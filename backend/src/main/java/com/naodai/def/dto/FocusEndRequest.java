package com.naodai.def.dto;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;

import javax.validation.constraints.Min;
import javax.validation.constraints.NotNull;

/**
 * 结束专注请求
 */
@ApiModel("结束专注请求")
public class FocusEndRequest {

    @NotNull(message = "专注记录ID不能为空")
    @ApiModelProperty(value = "专注记录ID", example = "1", required = true)
    private Long sessionId;

    @NotNull(message = "时长不能为空")
    @Min(value = 0, message = "时长不能为负")
    @ApiModelProperty(value = "专注时长（秒）", example = "1500", required = true)
    private Integer duration;  // 秒

    /** 是否完成 0:未完成 1:完成 */
    @ApiModelProperty(value = "是否完成 0放弃/1完成", example = "1")
    private Integer completed = 1;

    public Long getSessionId() { return sessionId; }
    public void setSessionId(Long sessionId) { this.sessionId = sessionId; }

    public Integer getDuration() { return duration; }
    public void setDuration(Integer duration) { this.duration = duration; }

    public Integer getCompleted() { return completed; }
    public void setCompleted(Integer completed) { this.completed = completed; }
}
