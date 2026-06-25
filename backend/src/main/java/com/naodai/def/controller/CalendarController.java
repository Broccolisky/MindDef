package com.naodai.def.controller;

import com.naodai.def.common.Result;
import com.naodai.def.entity.Task;
import com.naodai.def.service.CalendarService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;

/**
 * 日历接口
 */
@Api(tags = "06-日历")
@RestController
@RequestMapping("/api/calendar")
public class CalendarController {

    @Resource
    private CalendarService calendarService;

    @ApiOperation("获取月历数据（含重复任务展开）")
    @GetMapping
    public Result<Map<String, List<Task>>> getMonth(
            HttpServletRequest request,
            @RequestParam int year,
            @RequestParam int month) {
        Long userId = (Long) request.getAttribute("userId");
        Map<String, List<Task>> data = calendarService.getMonthCalendar(userId, year, month);
        return Result.ok(data);
    }
}
