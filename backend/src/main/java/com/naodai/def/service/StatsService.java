package com.naodai.def.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.naodai.def.entity.Task;
import com.naodai.def.mapper.TaskMapper;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 统计服务
 */
@Service
public class StatsService {

    @Resource
    private TaskMapper taskMapper;

    /**
     * 获取用户总体统计
     */
    public Map<String, Object> overview(Long userId) {
        Map<String, Object> stats = new HashMap<>();

        LambdaQueryWrapper<Task> allWrapper = new LambdaQueryWrapper<>();
        allWrapper.eq(Task::getUserId, userId);

        // 累计事项（不含已删除）
        LambdaQueryWrapper<Task> totalWrapper = new LambdaQueryWrapper<>();
        totalWrapper.eq(Task::getUserId, userId).ne(Task::getStatus, 3);
        stats.put("total", taskMapper.selectCount(totalWrapper));

        // 已完成
        LambdaQueryWrapper<Task> doneWrapper = new LambdaQueryWrapper<>();
        doneWrapper.eq(Task::getUserId, userId).eq(Task::getStatus, 2);
        stats.put("completed", taskMapper.selectCount(doneWrapper));

        // 已放弃（④象限删除的）
        LambdaQueryWrapper<Task> abandonedWrapper = new LambdaQueryWrapper<>();
        abandonedWrapper.eq(Task::getUserId, userId).eq(Task::getStatus, 3);
        stats.put("abandoned", taskMapper.selectCount(abandonedWrapper));

        // 各象限分布
        Map<Integer, Integer> quadrantDist = new HashMap<>();
        for (int q = 1; q <= 4; q++) {
            LambdaQueryWrapper<Task> qWrapper = new LambdaQueryWrapper<>();
            qWrapper.eq(Task::getUserId, userId)
                    .eq(Task::getQuadrant, q)
                    .ne(Task::getStatus, 3);
            quadrantDist.put(q, Math.toIntExact(taskMapper.selectCount(qWrapper)));
        }
        stats.put("quadrantDistribution", quadrantDist);

        // 本周完成
        LocalDateTime weekStart = LocalDateTime.now().with(java.time.DayOfWeek.MONDAY).withHour(0).withMinute(0).withSecond(0);
        LambdaQueryWrapper<Task> weekWrapper = new LambdaQueryWrapper<>();
        weekWrapper.eq(Task::getUserId, userId)
                .eq(Task::getStatus, 2)
                .ge(Task::getCompletedAt, weekStart);
        stats.put("thisWeek", taskMapper.selectCount(weekWrapper));

        // 本月完成
        LocalDateTime monthStart = LocalDateTime.now().withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0);
        LambdaQueryWrapper<Task> monthWrapper = new LambdaQueryWrapper<>();
        monthWrapper.eq(Task::getUserId, userId)
                .eq(Task::getStatus, 2)
                .ge(Task::getCompletedAt, monthStart);
        stats.put("thisMonth", taskMapper.selectCount(monthWrapper));

        return stats;
    }
}
