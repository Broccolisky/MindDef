package com.naodai.def.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.naodai.def.common.BusinessException;
import com.naodai.def.common.ResultCode;
import com.naodai.def.dto.AiTaskItem;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.naodai.def.entity.Faq;
import com.naodai.def.entity.Task;
import com.naodai.def.mapper.FaqMapper;
import com.naodai.def.mapper.TaskMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import org.springframework.http.client.SimpleClientHttpRequestFactory;

import javax.annotation.PostConstruct;
import javax.annotation.Resource;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedDeque;
import java.util.stream.Collectors;

/**
 * AI 服务 —— DeepSeek API 调用封装
 *
 * 功能：
 * 1. 文本解析（粘贴文本 → 提取事项列表）
 * 2. 智能问答（FAQ 知识库优先 → DeepSeek 兜底）
 * 3. 频率限制（每用户每分钟最多 10 次）
 */
@Service
public class AiService {

    private static final Logger log = LoggerFactory.getLogger(AiService.class);

    @Value("${deepseek.api-url}")
    private String apiUrl;

    @Value("${deepseek.api-key}")
    private String apiKey;

    @Value("${deepseek.model}")
    private String model;

    @Value("${deepseek.timeout:8000}")
    private int timeout;

    @Resource
    private FaqMapper faqMapper;

    @Resource
    private StatsService statsService;

    @Resource
    private TaskMapper taskMapper;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final RestTemplate restTemplate;

    /** 频率限制：key=userId, value=最近一次调用时间戳（线程安全） */
    private final Map<Long, ConcurrentLinkedDeque<Long>> rateLimitMap = new ConcurrentHashMap<>();

    public AiService() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(timeout);
        factory.setReadTimeout(timeout);
        this.restTemplate = new RestTemplate(factory);
    }

    // ════════════════════════════════════════════════════
    // 1. AI 文本解析
    // ════════════════════════════════════════════════════

    /**
     * 解析用户粘贴的文本，提取待办事项
     *
     * @param userId 用户 ID（用于频率限制）
     * @param rawText 用户粘贴的原始文本
     * @return 解析出的任务列表
     */
    public List<AiTaskItem> parseText(Long userId, String rawText) {
        // 频率检查
        checkRateLimit(userId);

        String systemPrompt = "你是一个任务管理助手。用户会给你一段文本，请从中提取出所有待办事项，" +
                "并以JSON格式返回。每个事项包含：" +
                "content（事项内容，简洁概括原意）、" +
                "importance（重要性0-100的整数，根据关键词判断：涉及工作/学习/健康/截止日期紧迫→高分，日常琐事/娱乐→低分）、" +
                "urgency（紧急性0-100的整数，根据时间紧迫程度判断：今天/明天→高分，本周→中分，无明确时间→低分）、" +
                "deadline（截止日期，格式YYYY-MM-DD，无明确日期则null）。" +
                "只返回JSON，不要其他内容。格式：{\"tasks\":[{\"content\":\"...\",\"importance\":80,\"urgency\":90,\"deadline\":\"2026-06-27\"}]}";

        String userMessage = rawText;

        try {
            String response = callDeepSeek(systemPrompt, userMessage, true);

            // 解析 JSON 响应
            Map<String, Object> result = objectMapper.readValue(response,
                    new TypeReference<Map<String, Object>>() {});

            @SuppressWarnings("unchecked")
            List<Map<String, Object>> taskList = (List<Map<String, Object>>) result.get("tasks");

            if (taskList == null || taskList.isEmpty()) {
                throw new BusinessException(ResultCode.BAD_REQUEST, "AI 未识别出待办事项，请尝试更清晰的描述");
            }

            // 转换为 AiTaskItem 并校验
            List<AiTaskItem> items = new ArrayList<>();
            for (Map<String, Object> t : taskList) {
                AiTaskItem item = new AiTaskItem();
                Object contentObj = t.get("content");
                item.setContent(contentObj != null ? String.valueOf(contentObj) : "未命名事项");

                // 校验 importance
                int importance = toInt(t.get("importance"), 50);
                item.setImportance(Math.max(0, Math.min(100, importance)));

                // 校验 urgency
                int urgency = toInt(t.get("urgency"), 50);
                item.setUrgency(Math.max(0, Math.min(100, urgency)));

                // deadline
                Object dl = t.get("deadline");
                item.setDeadline(dl != null && !"null".equals(String.valueOf(dl)) ? String.valueOf(dl) : null);

                // 计算象限和建议
                int quadrant = TaskService.calcQuadrant(item.getImportance(), item.getUrgency());
                item.setQuadrant(quadrant);
                item.setAdvice(TaskService.getAdvice(quadrant));

                items.add(item);
            }

            return items;

        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            log.error("AI 文本解析异常", e);
            // 降级：整体作为一条任务返回
            AiTaskItem fallback = new AiTaskItem();
            fallback.setContent(rawText.length() > 50 ? rawText.substring(0, 50) + "..." : rawText);
            fallback.setImportance(50);
            fallback.setUrgency(50);
            fallback.setQuadrant(TaskService.calcQuadrant(50, 50));
            fallback.setAdvice(TaskService.getAdvice(fallback.getQuadrant()));
            return Collections.singletonList(fallback);
        }
    }

    // ════════════════════════════════════════════════════
    // 2. AI 智能问答（FAQ 优先）
    // ════════════════════════════════════════════════════

    /**
     * FAQ 知识库问答 —— 先匹配本地 FAQ，无匹配则调用 DeepSeek
     * 系统提示词会注入用户当前的任务状态和统计数据
     */
    public String chat(Long userId, String question) {
        // 频率检查
        checkRateLimit(userId);

        // 第一步：FAQ 关键词匹配
        String faqAnswer = matchFaq(question);
        if (faqAnswer != null) {
            return faqAnswer;
        }

        // 第二步：DeepSeek 兜底（动态系统提示词含用户任务上下文）
        String systemPrompt = buildSystemPrompt(userId);

        try {
            return callDeepSeek(systemPrompt, question, false);
        } catch (Exception e) {
            log.error("AI 问答异常", e);
            return "抱歉，AI 服务暂时不可用，请稍后重试。您也可以在「使用指南」中查找帮助信息。";
        }
    }

    /**
     * 构建带用户任务上下文的系统提示词
     */
    private String buildSystemPrompt(Long userId) {
        StringBuilder sb = new StringBuilder();
        sb.append("你是 MindDef 任务管理应用的 AI 助手。");
        sb.append("MindDef 基于艾森豪威尔矩阵，通过重要性×紧急性双维度将任务分为四象限：");
        sb.append("①立刻做（重要+紧急）②计划做（重要+不紧急）③简化做（不重要+紧急）④不做（不重要+不紧急）。");
        sb.append("请用简洁友好的方式回答用户问题，控制在 200 字以内。");

        try {
            // 注入用户任务统计
            Map<String, Object> stats = statsService.overview(userId);
            if (stats != null && !stats.isEmpty()) {
                sb.append("\n\n## 用户当前任务统计\n");
                sb.append("- 总任务: ").append(stats.getOrDefault("total", 0)).append(" 条");
                sb.append("（已完成: ").append(stats.getOrDefault("completed", 0));
                sb.append("，已放弃: ").append(stats.getOrDefault("abandoned", 0)).append("）\n");

                @SuppressWarnings("unchecked")
                Map<Integer, Integer> dist = (Map<Integer, Integer>) stats.get("quadrantDistribution");
                if (dist != null) {
                    sb.append("- ①立刻做: ").append(dist.getOrDefault(1, 0)).append(" 条  ");
                    sb.append("②计划做: ").append(dist.getOrDefault(2, 0)).append(" 条  ");
                    sb.append("③简化做: ").append(dist.getOrDefault(3, 0)).append(" 条  ");
                    sb.append("④不做: ").append(dist.getOrDefault(4, 0)).append(" 条\n");
                }
                sb.append("- 本周完成: ").append(stats.getOrDefault("thisWeek", 0)).append(" 条  ");
                sb.append("本月完成: ").append(stats.getOrDefault("thisMonth", 0)).append(" 条\n");
            }

            // 注入活跃任务列表（top 10，优先 Q1 + 有 deadline 的）
            LambdaQueryWrapper<Task> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(Task::getUserId, userId)
                   .in(Task::getStatus, 0, 1)  // 待办 + 进行中
                   .orderByAsc(Task::getQuadrant)
                   .orderByDesc(Task::getImportance)
                   .last("LIMIT 10");
            List<Task> activeTasks = taskMapper.selectList(wrapper);

            if (activeTasks != null && !activeTasks.isEmpty()) {
                sb.append("\n## 用户待处理任务（部分）\n");
                for (Task t : activeTasks) {
                    sb.append("- [").append(getQuadrantName(t.getQuadrant())).append("] ");
                    sb.append(t.getContent());
                    if (t.getDeadline() != null) {
                        sb.append("（截止: ").append(t.getDeadline()).append("）");
                    }
                    sb.append("\n");
                }
            }

            sb.append("\n基于以上数据，若用户询问任务建议/优先级/安排等问题，请结合其实际任务状况给出个性化建议。");
            sb.append("若用户问的是通用问题，正常回答即可。");

        } catch (Exception e) {
            log.warn("构建任务上下文失败，使用基础系统提示词", e);
        }

        return sb.toString();
    }

    private String getQuadrantName(int q) {
        switch (q) {
            case 1: return "①立刻做";
            case 2: return "②计划做";
            case 3: return "③简化做";
            case 4: return "④不做";
            default: return "象限" + q;
        }
    }

    // ════════════════════════════════════════════════════
    // 3. 核心 API 调用
    // ════════════════════════════════════════════════════

    /**
     * 调用 DeepSeek API
     *
     * @param systemPrompt 系统提示词
     * @param userMessage  用户消息
     * @param jsonMode     是否启用 JSON 输出模式
     * @return AI 返回的文本内容
     */
    private String callDeepSeek(String systemPrompt, String userMessage, boolean jsonMode) {
        try {
            // 构建请求体
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("model", model);

            List<Map<String, String>> messages = new ArrayList<>();

            Map<String, String> systemMsg = new HashMap<>();
            systemMsg.put("role", "system");
            systemMsg.put("content", systemPrompt);
            messages.add(systemMsg);

            Map<String, String> userMsg = new HashMap<>();
            userMsg.put("role", "user");
            userMsg.put("content", userMessage);
            messages.add(userMsg);

            requestBody.put("messages", messages);
            requestBody.put("temperature", 0.3);
            requestBody.put("max_tokens", jsonMode ? 2000 : 500);

            if (jsonMode) {
                Map<String, String> responseFormat = new HashMap<>();
                responseFormat.put("type", "json_object");
                requestBody.put("response_format", responseFormat);
            }

            // 构建 HTTP 请求
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer " + apiKey);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);

            log.debug("调用 DeepSeek API: {}", apiUrl);
            ResponseEntity<Map> response = restTemplate.exchange(
                    apiUrl, HttpMethod.POST, request, Map.class);

            // 解析响应
            Map<String, Object> responseBody = response.getBody();
            if (responseBody == null) {
                throw new BusinessException(ResultCode.SERVER_ERROR, "AI 服务返回为空");
            }

            @SuppressWarnings("unchecked")
            List<Map<String, Object>> choices = (List<Map<String, Object>>) responseBody.get("choices");
            if (choices == null || choices.isEmpty()) {
                throw new BusinessException(ResultCode.SERVER_ERROR, "AI 服务返回格式异常");
            }

            @SuppressWarnings("unchecked")
            Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
            Object contentObj = message.get("content");
            if (contentObj == null) {
                throw new BusinessException(ResultCode.SERVER_ERROR, "AI 服务返回格式异常");
            }
            return String.valueOf(contentObj);

        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            log.error("DeepSeek API 调用失败", e);
            throw new BusinessException(ResultCode.SERVER_ERROR, "AI 暂时不可用，请使用手动输入");
        }
    }

    // ════════════════════════════════════════════════════
    // 4. FAQ 匹配
    // ════════════════════════════════════════════════════

    /**
     * 根据用户问题匹配 FAQ 知识库
     * 简单关键词匹配策略：计算问题与 FAQ 问题的共同词数量
     *
     * @return 匹配到的答案，无匹配返回 null
     */
    private String matchFaq(String question) {
        List<Faq> faqs = faqMapper.selectList(null);
        if (faqs.isEmpty()) return null;

        String[] queryWords = question.toLowerCase().split("\\s+");

        Faq bestMatch = null;
        int bestScore = 0;

        for (Faq faq : faqs) {
            int score = 0;
            String faqLower = faq.getQuestion().toLowerCase();

            for (String word : queryWords) {
                if (word.length() >= 2 && faqLower.contains(word)) {
                    score++;
                }
            }

            if (score > bestScore) {
                bestScore = score;
                bestMatch = faq;
            }
        }

        // 匹配阈值：至少匹配 2 个词
        if (bestMatch != null && bestScore >= 2) {
            log.info("FAQ 匹配成功: {} (score={})", bestMatch.getQuestion(), bestScore);
            return bestMatch.getAnswer();
        }

        return null;
    }

    // ════════════════════════════════════════════════════
    // 5. 频率限制
    // ════════════════════════════════════════════════════

    /**
     * 检查用户调用频率（每用户每分钟最多 10 次）
     */
    private void checkRateLimit(Long userId) {
        long now = System.currentTimeMillis();
        long oneMinuteAgo = now - 60_000;

        rateLimitMap.compute(userId, (k, v) -> {
            if (v == null) v = new ConcurrentLinkedDeque<>();
            // 清理过期记录
            v.removeIf(t -> t < oneMinuteAgo);
            if (v.size() >= 10) {
                throw new BusinessException(ResultCode.BAD_REQUEST, "AI 调用太频繁，请稍后再试（每分钟限 10 次）");
            }
            v.add(now);
            return v.isEmpty() ? null : v;  // 空队列时移除条目，防止内存泄漏
        });
    }

    // ════════════════════════════════════════════════════
    // 辅助方法
    // ════════════════════════════════════════════════════

    private int toInt(Object obj, int defaultValue) {
        if (obj == null) return defaultValue;
        try {
            return Integer.parseInt(String.valueOf(obj));
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }
}
