package com.naodai.def.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.naodai.def.common.BusinessException;
import com.naodai.def.common.ResultCode;
import com.naodai.def.dto.*;
import com.naodai.def.entity.Task;
import com.naodai.def.mapper.TaskMapper;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 任务服务 —— 核心业务逻辑
 *
 * 涵盖：创建/列表/编辑/移动象限/排程/完成/删除
 * 含象限判定算法和用户归属校验
 */
@Service
public class TaskService {

    @Resource
    private TaskMapper taskMapper;

    /**
     * 象限判定算法
     *
     * 重要性 > 50 && 紧急性 > 50  → ① 立刻做
     * 重要性 > 50 && 紧急性 ≤ 50  → ② 计划做
     * 重要性 ≤ 50 && 紧急性 > 50  → ③ 简化做
     * 重要性 ≤ 50 && 紧急性 ≤ 50  → ④ 不做
     */
    public static int calcQuadrant(int importance, int urgency) {
        if (importance > 50 && urgency > 50)  return 1;
        if (importance > 50)                   return 2;
        if (urgency > 50)                      return 3;
        return 4;
    }

    /**
     * 根据象限返回建议文案
     */
    public static String getAdvice(int quadrant) {
        switch (quadrant) {
            case 1: return "现在就做";
            case 2: return "排进日程";
            case 3: return "能简化就简化";
            case 4: return "考虑放弃";
            default: return "";
        }
    }

    /**
     * 根据重要性和紧急性返回滑块标签
     */
    public static String getImportanceLabel(int val) {
        if (val <= 25) return "不重要";
        if (val <= 50) return "一般";
        if (val <= 75) return "重要";
        return "非常重要";
    }

    public static String getUrgencyLabel(int val) {
        if (val <= 25) return "不紧急";
        if (val <= 50) return "有点急";
        if (val <= 75) return "比较急";
        return "非常紧急";
    }

    // ──────────── 创建 ────────────

    /**
     * 创建任务（手动 / 引导）
     */
    public Task create(Long userId, TaskCreateRequest req) {
        Task task = new Task();
        task.setUserId(userId);
        task.setContent(req.getContent());
        task.setImportance(req.getImportance());
        task.setUrgency(req.getUrgency());
        task.setQuadrant(calcQuadrant(req.getImportance(), req.getUrgency()));
        task.setSource(req.getSource() != null ? req.getSource() : 1);

        // 解析截止日期
        if (req.getDeadline() != null && !req.getDeadline().isEmpty()) {
            try {
                task.setDeadline(LocalDate.parse(req.getDeadline()));
            } catch (Exception e) {
                throw new BusinessException(ResultCode.BAD_REQUEST, "截止日期格式错误，须为 yyyy-MM-dd");
            }
        }

        task.setStatus(0); // 待办
        taskMapper.insert(task);
        return task;
    }

    // ──────────── 列表 ────────────

    /**
     * 获取用户任务列表，支持按象限/状态筛选
     */
    public List<Task> list(Long userId, TaskListQuery query) {
        LambdaQueryWrapper<Task> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Task::getUserId, userId);

        // 默认不返回已删除
        if (query != null && query.getStatus() != null) {
            wrapper.eq(Task::getStatus, query.getStatus());
        } else {
            wrapper.ne(Task::getStatus, 3);
        }

        // 按象限筛选
        if (query != null && query.getQuadrant() != null && query.getQuadrant() > 0) {
            wrapper.eq(Task::getQuadrant, query.getQuadrant());
        }

        wrapper.orderByDesc(Task::getCreatedAt);
        return taskMapper.selectList(wrapper);
    }

    // ──────────── 编辑 ────────────

    /**
     * 编辑任务内容
     */
    public Task update(Long userId, Long taskId, TaskUpdateRequest req) {
        Task task = checkOwnership(userId, taskId);
        task.setContent(req.getContent());
        taskMapper.updateById(task);
        return task;
    }

    // ──────────── 移动象限 ────────────

    /**
     * 移动任务到指定象限
     */
    public Task moveQuadrant(Long userId, Long taskId, QuadrantMoveRequest req) {
        Task task = checkOwnership(userId, taskId);
        task.setQuadrant(req.getQuadrant());

        // 移出②象限时自动清空计划日期（②象限专属排程字段）
        if (req.getQuadrant() != 2) {
            task.setScheduledDate(null);
        }

        taskMapper.updateById(task);
        return task;
    }

    // ──────────── 排程 ────────────

    /**
     * 设置计划日期（②象限专用）
     */
    public Task schedule(Long userId, Long taskId, ScheduleRequest req) {
        Task task = checkOwnership(userId, taskId);
        if (req.getScheduledDate() != null && !req.getScheduledDate().isEmpty()) {
            try {
                task.setScheduledDate(LocalDate.parse(req.getScheduledDate()));
            } catch (Exception e) {
                throw new BusinessException(ResultCode.BAD_REQUEST, "日期格式错误，须为 yyyy-MM-dd");
            }
        } else {
            task.setScheduledDate(null);
        }
        taskMapper.updateById(task);
        return task;
    }

    // ──────────── 完成 ────────────

    /**
     * 标记任务完成
     */
    public Task complete(Long userId, Long taskId) {
        Task task = checkOwnership(userId, taskId);
        if (task.getStatus() == 3) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "该事项已被删除");
        }
        if (task.getStatus() == 2) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "该事项已完成");
        }
        task.setStatus(2);
        task.setCompletedAt(LocalDateTime.now());
        taskMapper.updateById(task);
        return task;
    }

    // ──────────── 删除（软删除） ────────────

    /**
     * 软删除任务（status = 3）
     * MyBatis-Plus 逻辑删除：deleteById 自动将 status 置为 3，而不是物理删除
     */
    public void delete(Long userId, Long taskId) {
        checkOwnership(userId, taskId);           // 归属校验（不过则抛异常）
        taskMapper.deleteById(taskId);            // 触发 MyBatis-Plus 逻辑删除
    }

    // ──────────── 辅助方法 ────────────

    /**
     * 校验任务归属 —— 只允许操作自己的任务
     * @return 任务实体
     * @throws BusinessException 403 若非本人任务
     */
    private Task checkOwnership(Long userId, Long taskId) {
        Task task = taskMapper.selectById(taskId);
        if (task == null) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "事项不存在");
        }
        if (!task.getUserId().equals(userId)) {
            throw new BusinessException(ResultCode.FORBIDDEN, "无权操作他人的事项");
        }
        return task;
    }
}
