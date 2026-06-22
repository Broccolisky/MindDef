package com.naodai.def.controller;

import com.naodai.def.common.Result;
import com.naodai.def.dto.FocusEndRequest;
import com.naodai.def.dto.FocusStartRequest;
import com.naodai.def.entity.FocusSession;
import com.naodai.def.service.FocusService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;

/**
 * 专注接口 — 番茄钟开始 / 结束
 */
@Api(tags = "04-番茄钟")
@RestController
@RequestMapping("/api/focus")
public class FocusController {

    @Resource
    private FocusService focusService;

    private Long getUserId(HttpServletRequest request) {
        return (Long) request.getAttribute("userId");
    }

    /**
     * 开始专注（任务状态→进行中，创建 focus_session 记录）
     * POST /api/focus/start
     */
    @ApiOperation("开始专注")
    @PostMapping("/start")
    public Result<FocusSession> start(@Valid @RequestBody FocusStartRequest req,
                                      HttpServletRequest request) {
        FocusSession session = focusService.start(getUserId(request), req);
        return Result.ok(session);
    }

    /**
     * 结束专注（记录时长 + 完成/放弃状态）
     * POST /api/focus/end
     */
    @ApiOperation("结束专注")
    @PostMapping("/end")
    public Result<FocusSession> end(@Valid @RequestBody FocusEndRequest req,
                                    HttpServletRequest request) {
        FocusSession session = focusService.end(getUserId(request), req);
        return Result.ok(session);
    }
}
