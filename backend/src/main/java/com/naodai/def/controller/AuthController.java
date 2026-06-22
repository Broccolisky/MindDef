package com.naodai.def.controller;

import com.naodai.def.common.Result;
import com.naodai.def.dto.LoginRequest;
import com.naodai.def.dto.LoginResponse;
import com.naodai.def.dto.RegisterRequest;
import com.naodai.def.service.AuthService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;

/**
 * 认证接口 — 注册 / 登录（无需 Token）
 */
@Api(tags = "01-认证")
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Resource
    private AuthService authService;

    /**
     * 注册
     * POST /api/auth/register
     */
    @ApiOperation("用户注册")
    @PostMapping("/register")
    public Result<?> register(@Valid @RequestBody RegisterRequest req) {
        authService.register(req);
        return Result.ok();
    }

    /**
     * 登录
     * POST /api/auth/login
     */
    @ApiOperation("用户登录")
    @PostMapping("/login")
    public Result<LoginResponse> login(@Valid @RequestBody LoginRequest req) {
        LoginResponse resp = authService.login(req);
        return Result.ok(resp);
    }
}
