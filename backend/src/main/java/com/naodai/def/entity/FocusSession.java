package com.naodai.def.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 专注记录实体
 */
@Data
@TableName("focus_session")
public class FocusSession {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 关联事项 ID */
    private Long taskId;

    /** 专注时长（秒） */
    private Integer duration;

    /** 0:未完成 1:完成 */
    private Integer completed;

    /** 开始时间 */
    private LocalDateTime startedAt;
}
