package com.naodai.def.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * FAQ 知识库实体
 */
@Data
@TableName("faq")
public class Faq {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 分类（如：使用指南/技术问题/账户问题） */
    private String category;

    /** 问题 */
    private String question;

    /** 答案 */
    private String answer;

    /** 创建时间 */
    private LocalDateTime createdAt;
}
