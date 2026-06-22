package com.naodai.def.controller;

import com.naodai.def.common.Result;
import com.naodai.def.dto.AiChatRequest;
import com.naodai.def.dto.AiParseRequest;
import com.naodai.def.dto.AiTaskItem;
import com.naodai.def.service.AiService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AI 接口 — 文本解析 + 智能问答
 */
@Api(tags = "03-AI智能")
@RestController
@RequestMapping("/api")
public class AiController {

    @Resource
    private AiService aiService;

    private Long getUserId(HttpServletRequest request) {
        return (Long) request.getAttribute("userId");
    }

    /**
     * AI 文本解析 —— 粘贴文本 → 提取事项列表
     * POST /api/task/ai-parse
     */
    @ApiOperation("AI 文本解析（粘贴文本→提取事项）")
    @PostMapping("/task/ai-parse")
    public Result<List<AiTaskItem>> aiParse(@Valid @RequestBody AiParseRequest req,
                                            HttpServletRequest request) {
        List<AiTaskItem> items = aiService.parseText(getUserId(request), req.getText());
        return Result.ok(items);
    }

    /**
     * AI 智能问答（FAQ 知识库优先 → DeepSeek 兜底）
     * POST /api/ai/chat
     */
    @ApiOperation("AI 智能问答（FAQ优先+DeepSeek兜底）")
    @PostMapping("/ai/chat")
    public Result<Map<String, String>> chat(@Valid @RequestBody AiChatRequest req,
                                            HttpServletRequest request) {
        String answer = aiService.chat(getUserId(request), req.getQuestion());
        Map<String, String> data = new HashMap<>();
        data.put("answer", answer);
        return Result.ok(data);
    }
}
