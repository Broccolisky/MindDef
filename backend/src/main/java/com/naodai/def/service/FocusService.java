package com.naodai.def.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.naodai.def.common.BusinessException;
import com.naodai.def.common.ResultCode;
import com.naodai.def.dto.FocusEndRequest;
import com.naodai.def.dto.FocusStartRequest;
import com.naodai.def.entity.FocusSession;
import com.naodai.def.entity.Task;
import com.naodai.def.mapper.FocusSessionMapper;
import com.naodai.def.mapper.TaskMapper;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.LocalDateTime;

/**
 * 专注服务 —— 番茄钟开始/结束
 */
@Service
public class FocusService {

    @Resource
    private FocusSessionMapper focusSessionMapper;

    @Resource
    private TaskMapper taskMapper;

    /**
     * 开始专注
     * 验证任务存在且属于当前用户，将任务状态设为"进行中"
     */
    public FocusSession start(Long userId, FocusStartRequest req) {
        // 校验任务存在
        Task task = taskMapper.selectById(req.getTaskId());
        if (task == null) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "事项不存在");
        }
        if (!task.getUserId().equals(userId)) {
            throw new BusinessException(ResultCode.FORBIDDEN, "无权操作他人的事项");
        }
        if (task.getStatus() == 3) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "该事项已被删除");
        }
        if (task.getStatus() == 1) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "该事项已在专注中");
        }
        if (task.getStatus() == 2) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "该事项已完成");
        }

        // 更新任务状态为进行中
        task.setStatus(1);
        taskMapper.updateById(task);

        // 创建专注记录
        FocusSession session = new FocusSession();
        session.setTaskId(req.getTaskId());
        session.setStartedAt(LocalDateTime.now());
        session.setCompleted(0);
        session.setDuration(0);
        focusSessionMapper.insert(session);

        return session;
    }

    /**
     * 结束专注
     * 记录时长和完成状态
     */
    public FocusSession end(Long userId, FocusEndRequest req) {
        FocusSession session = focusSessionMapper.selectById(req.getSessionId());
        if (session == null) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "专注记录不存在");
        }

        // 防止重复结束
        if (session.getDuration() != null && session.getDuration() > 0) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "该专注记录已结束");
        }

        // 校验任务归属
        if (session.getTaskId() == null) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "专注记录数据异常");
        }
        Task task = taskMapper.selectById(session.getTaskId());
        if (task == null || !task.getUserId().equals(userId)) {
            throw new BusinessException(ResultCode.FORBIDDEN, "无权操作");
        }

        session.setDuration(req.getDuration());
        session.setCompleted(req.getCompleted() != null ? req.getCompleted() : 1);
        focusSessionMapper.updateById(session);

        // 重置任务状态：完成→2，放弃→0
        boolean completed = req.getCompleted() != null && req.getCompleted() == 1;
        task.setStatus(completed ? 2 : 0);
        if (completed) {
            task.setCompletedAt(LocalDateTime.now());
        }
        taskMapper.updateById(task);

        return session;
    }
}
