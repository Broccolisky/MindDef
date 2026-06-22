package com.naodai.def.controller;

import com.naodai.def.common.Result;
import com.naodai.def.entity.User;
import com.naodai.def.service.UserService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.util.Map;

/**
 * 用户接口 — 个人信息 / 昵称 / 密码
 */
@Api(tags = "05-个人中心")
@RestController
@RequestMapping("/api/user")
public class UserController {

    @Resource
    private UserService userService;

    private Long getUserId(HttpServletRequest request) {
        return (Long) request.getAttribute("userId");
    }

    /**
     * 获取个人信息（password 字段返回 null）
     * GET /api/user/profile
     */
    @ApiOperation("获取个人信息")
    @GetMapping("/profile")
    public Result<User> profile(HttpServletRequest request) {
        User user = userService.profile(getUserId(request));
        return Result.ok(user);
    }

    /**
     * 修改昵称（1-32 字符）
     * PUT /api/user/nickname
     */
    @ApiOperation("修改昵称")
    @PutMapping("/nickname")
    public Result<?> updateNickname(@RequestBody Map<String, String> body, HttpServletRequest request) {
        String nickname = body.get("nickname");
        userService.updateNickname(getUserId(request), nickname);
        return Result.ok();
    }

    /**
     * 修改密码（需验证原密码，新密码6-20位）
     * PUT /api/user/password
     */
    @ApiOperation("修改密码")
    @PutMapping("/password")
    public Result<?> updatePassword(@RequestBody Map<String, String> body, HttpServletRequest request) {
        String oldPassword = body.get("oldPassword");
        String newPassword = body.get("newPassword");
        userService.updatePassword(getUserId(request), oldPassword, newPassword);
        return Result.ok();
    }
}
