package com.naodai.def.dto;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;

/**
 * 排程请求 DTO
 */
@ApiModel("排程请求")
public class ScheduleRequest {

    /** 计划日期，格式 yyyy-MM-dd */
    @ApiModelProperty(value = "计划日期", example = "2026-06-30")
    private String scheduledDate;

    public String getScheduledDate() { return scheduledDate; }
    public void setScheduledDate(String scheduledDate) { this.scheduledDate = scheduledDate; }
}
