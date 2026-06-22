package com.naodai.def.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.naodai.def.common.BusinessException;
import com.naodai.def.common.JwtUtil;
import com.naodai.def.common.ResultCode;
import com.naodai.def.dto.LoginRequest;
import com.naodai.def.dto.LoginResponse;
import com.naodai.def.dto.RegisterRequest;
import com.naodai.def.entity.User;
import com.naodai.def.mapper.UserMapper;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * 认证服务 —— 注册 / 登录
 */
@Service
public class AuthService {

    @Resource
    private UserMapper userMapper;

    @Resource
    private JwtUtil jwtUtil;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    /**
     * 注册
     * 1. 校验用户名唯一
     * 2. BCrypt 加密密码
     * 3. 入库
     */
    public void register(RegisterRequest req) {
        // 检查用户名是否已存在
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getUsername, req.getUsername());
        if (userMapper.selectCount(wrapper) > 0) {
            throw new BusinessException(ResultCode.CONFLICT, "用户名已存在");
        }

        User user = new User();
        user.setUsername(req.getUsername());
        user.setPassword(passwordEncoder.encode(req.getPassword()));
        user.setNickname(req.getUsername()); // 默认昵称 = 用户名
        userMapper.insert(user);
    }

    /**
     * 登录
     * 1. 查用户
     * 2. BCrypt 校验密码
     * 3. 生成 JWT
     */
    public LoginResponse login(LoginRequest req) {
        // 查用户
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getUsername, req.getUsername());
        User user = userMapper.selectOne(wrapper);

        if (user == null) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "用户名或密码错误");
        }

        // 校验密码
        if (!passwordEncoder.matches(req.getPassword(), user.getPassword())) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "用户名或密码错误");
        }

        // 生成 JWT
        String token = jwtUtil.generateToken(user.getId());

        return new LoginResponse(token, user.getId(), user.getNickname());
    }
}
