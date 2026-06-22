package com.naodai.def;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * MindDef 应用主启动类
 */
@SpringBootApplication
@MapperScan("com.naodai.def.mapper")
public class MindDefApplication {

    public static void main(String[] args) {
        SpringApplication.run(MindDefApplication.class, args);
    }
}
