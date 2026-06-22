package com.naodai.def.controller;

import com.naodai.def.common.Result;
import com.naodai.def.dto.*;
import com.naodai.def.entity.Task;
import com.naodai.def.service.TaskService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.util.List;

/**
 * 任务接口 — 核心 CRUD + 象限管理
 */
@Api(tags = "02-任务管理")
@RestController
@RequestMapping("/api/task")
public class TaskController {

    @Resource
    private TaskService taskService;

    /**
     * 从 JwtInterceptor 设置的 request attribute 中获取当前用户 ID
     */
    private Long getUserId(HttpServletRequest request) {
        return (Long) request.getAttribute("userId");
    }

    /**
     * 创建任务（手动 / 引导）
     * POST /api/task
     */
    @ApiOperation("创建任务")
    @PostMapping
    public Result<Task> create(@Valid @RequestBody TaskCreateRequest req, HttpServletRequest request) {
        Task task = taskService.create(getUserId(request), req);
        return Result.ok(task);
    }

    /**
     * 获取任务列表
     * GET /api/task/list?quadrant=1&status=0
     */
    @ApiOperation("获取任务列表（支持按象限/状态筛选）")
    @GetMapping("/list")
    public Result<List<Task>> list(TaskListQuery query, HttpServletRequest request) {
        List<Task> list = taskService.list(getUserId(request), query);
        return Result.ok(list);
    }

    /**
     * 编辑任务内容
     * PUT /api/task/{id}
     */
    @ApiOperation("编辑任务内容")
    @PutMapping("/{id}")
    public Result<Task> update(@PathVariable Long id,
                               @Valid @RequestBody TaskUpdateRequest req,
                               HttpServletRequest request) {
        Task task = taskService.update(getUserId(request), id, req);
        return Result.ok(task);
    }

    /**
     * 移动象限
     * PUT /api/task/{id}/quadrant
     */
    @ApiOperation("移动任务象限")
    @PutMapping("/{id}/quadrant")
    public Result<Task> moveQuadrant(@PathVariable Long id,
                                     @Valid @RequestBody QuadrantMoveRequest req,
                                     HttpServletRequest request) {
        Task task = taskService.moveQuadrant(getUserId(request), id, req);
        return Result.ok(task);
    }

    /**
     * 设置计划日期（②象限）
     * PUT /api/task/{id}/schedule
     */
    @ApiOperation("设置计划日期")
    @PutMapping("/{id}/schedule")
    public Result<Task> schedule(@PathVariable Long id,
                                 @RequestBody ScheduleRequest req,
                                 HttpServletRequest request) {
        Task task = taskService.schedule(getUserId(request), id, req);
        return Result.ok(task);
    }

    /**
     * 标记完成
     * PUT /api/task/{id}/complete
     */
    @ApiOperation("标记任务完成")
    @PutMapping("/{id}/complete")
    public Result<Task> complete(@PathVariable Long id, HttpServletRequest request) {
        Task task = taskService.complete(getUserId(request), id);
        return Result.ok(task);
    }

    /**
     * 删除任务（软删除，status→3）
     * DELETE /api/task/{id}
     */
    @ApiOperation("删除任务（软删除）")
    @DeleteMapping("/{id}")
    public Result<?> delete(@PathVariable Long id, HttpServletRequest request) {
        taskService.delete(getUserId(request), id);
        return Result.ok();
    }
}
