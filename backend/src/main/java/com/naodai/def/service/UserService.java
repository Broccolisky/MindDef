package com.naodai.def.service;

import com.naodai.def.common.BusinessException;
import com.naodai.def.common.ResultCode;
import com.naodai.def.entity.User;
import com.naodai.def.mapper.UserMapper;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * 用户服务 —— 个人信息 / 修改昵称 / 修改密码
 */
@Service
public class UserService {

    @Resource
    private UserMapper userMapper;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    /**
     * 获取个人信息
     */
    public User profile(Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "用户不存在");
        }
        // 不返回密码
        user.setPassword(null);
        return user;
    }

    /**
     * 修改昵称
     */
    public void updateNickname(Long userId, String nickname) {
        if (nickname == null || nickname.trim().isEmpty()) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "昵称不能为空");
        }
        if (nickname.length() > 32) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "昵称最长32个字符");
        }
        User user = new User();
        user.setId(userId);
        user.setNickname(nickname.trim());
        userMapper.updateById(user);
    }

    /**
     * 修改密码
     */
    public void updatePassword(Long userId, String oldPassword, String newPassword) {
        if (oldPassword == null || newPassword == null) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "密码不能为空");
        }
        if (newPassword.length() < 6 || newPassword.length() > 20) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "新密码须6-20位");
        }

        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "用户不存在");
        }

        // 校验旧密码
        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "原密码错误");
        }

        // 加密新密码
        User updateUser = new User();
        updateUser.setId(userId);
        updateUser.setPassword(passwordEncoder.encode(newPassword));
        userMapper.updateById(updateUser);
    }
}
