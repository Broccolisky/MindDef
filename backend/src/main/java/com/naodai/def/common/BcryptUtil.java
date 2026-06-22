package com.naodai.def.common;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/**
 * BCrypt 工具 —— 生成密码哈希（开发阶段辅助用）
 *
 * 运行方式：mvn exec:java 或 IDE 直接运行 main
 */
public class BcryptUtil {

    private static final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    /**
     * 加密明文密码
     */
    public static String encode(String rawPassword) {
        return encoder.encode(rawPassword);
    }

    /**
     * 校验密码
     */
    public static boolean matches(String rawPassword, String encodedPassword) {
        return encoder.matches(rawPassword, encodedPassword);
    }

    /**
     * 命令行快速生成 BCrypt 哈希
     * 用法：java BcryptUtil 123456
     */
    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("用法: java BcryptUtil <明文密码>");
            return;
        }
        System.out.println("BCrypt Hash: " + encode(args[0]));
    }
}
