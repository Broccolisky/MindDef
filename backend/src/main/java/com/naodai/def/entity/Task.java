package com.naodai.def.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 事项表实体
 */
@Data
@TableName("task")
public class Task {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 所属用户 ID */
    private Long userId;

    /** 事项内容 */
    private String content;

    /** 重要性 0-100 */
    private Integer importance;

    /** 紧急性 0-100 */
    private Integer urgency;

    /** 象限 1:立刻做 2:计划做 3:简化做 4:不做 */
    private Integer quadrant;

    /** 截止日期（可选） */
    private LocalDate deadline;

    /** 来源 1:手动 2:AI识别 3:引导 */
    private Integer source;

    /** 状态 0:待办 1:进行中 2:完成 3:已删除 */
    private Integer status;

    /** 计划日期（②象限排程） */
    private LocalDate scheduledDate;

    /** 重复模式 0:不重复 1:每日 2:仅工作日 3:仅休息日 */
    private Integer repeatMode;

    /** 创建时间 */
    private LocalDateTime createdAt;

    /** 完成时间 */
    private LocalDateTime completedAt;
}
