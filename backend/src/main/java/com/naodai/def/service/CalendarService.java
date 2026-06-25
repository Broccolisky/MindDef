package com.naodai.def.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.naodai.def.entity.Task;
import com.naodai.def.mapper.TaskMapper;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.*;

/**
 * 日历服务 —— 展开重复任务到指定月份各日
 */
@Service
public class CalendarService {

    @Resource
    private TaskMapper taskMapper;

    /**
     * 获取某月日历数据
     *
     * @param userId 用户 ID
     * @param year   年份
     * @param month  月份 (1-12)
     * @return Map<日期字符串 yyyy-MM-dd, 当日任务列表>
     */
    public Map<String, List<Task>> getMonthCalendar(Long userId, int year, int month) {
        Map<String, List<Task>> calendar = new LinkedHashMap<>();

        YearMonth ym = YearMonth.of(year, month);
        LocalDate firstDay = ym.atDay(1);
        LocalDate lastDay = ym.atEndOfMonth();

        // 初始化每天的空列表
        for (LocalDate d = firstDay; !d.isAfter(lastDay); d = d.plusDays(1)) {
            calendar.put(d.toString(), new ArrayList<>());
        }

        // 获取用户活跃任务（status = 0 或 1）
        LambdaQueryWrapper<Task> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Task::getUserId, userId)
               .in(Task::getStatus, 0, 1);
        List<Task> allTasks = taskMapper.selectList(wrapper);

        if (allTasks == null || allTasks.isEmpty()) {
            return calendar;
        }

        for (Task task : allTasks) {
            Integer repeatMode = task.getRepeatMode() != null ? task.getRepeatMode() : 0;

            if (repeatMode == null || repeatMode == 0) {
                // 不重复：仅显示在 deadline 当天
                if (task.getDeadline() != null) {
                    String ds = task.getDeadline().toString();
                    List<Task> dayTasks = calendar.get(ds);
                    if (dayTasks != null) {
                        dayTasks.add(task);
                    }
                }
            } else {
                // 重复任务：展开到月内每一天
                for (LocalDate d = firstDay; !d.isAfter(lastDay); d = d.plusDays(1)) {
                    if (matchesRepeat(d, repeatMode)) {
                        calendar.get(d.toString()).add(task);
                    }
                }
            }
        }

        return calendar;
    }

    /**
     * 判断某日是否匹配重复模式
     */
    private boolean matchesRepeat(LocalDate date, int repeatMode) {
        DayOfWeek dow = date.getDayOfWeek();
        switch (repeatMode) {
            case 1: // 每日
                return true;
            case 2: // 仅工作日
                return dow != DayOfWeek.SATURDAY && dow != DayOfWeek.SUNDAY;
            case 3: // 仅休息日
                return dow == DayOfWeek.SATURDAY || dow == DayOfWeek.SUNDAY;
            default:
                return false;
        }
    }
}
