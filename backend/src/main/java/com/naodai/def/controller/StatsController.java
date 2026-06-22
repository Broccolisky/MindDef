package com.naodai.def.controller;

import com.naodai.def.common.Result;
import com.naodai.def.service.StatsService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.util.Map;

/**
 * 统计接口 — 任务概览 / 象限分布 / 周月统计
 */
@Api(tags = "05-决策统计")
@RestController
@RequestMapping("/api/stats")
public class StatsController {

    @Resource
    private StatsService statsService;

    private Long getUserId(HttpServletRequest request) {
        return (Long) request.getAttribute("userId");
    }

    /**
     * 总体统计（累计/完成/放弃 + 象限分布 + 本周/本月）
     * GET /api/stats/overview
     */
    @ApiOperation("获取决策统计概览")
    @GetMapping("/overview")
    public Result<Map<String, Object>> overview(HttpServletRequest request) {
        Map<String, Object> stats = statsService.overview(getUserId(request));
        return Result.ok(stats);
    }
}
