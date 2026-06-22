package com.naodai.def.dto;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;

import javax.validation.constraints.NotNull;

/**
 * 开始专注请求
 */
@ApiModel("开始专注请求")
public class FocusStartRequest {

    @NotNull(message = "事项ID不能为空")
    @ApiModelProperty(value = "事项ID", example = "1", required = true)
    private Long taskId;

    public Long getTaskId() { return taskId; }
    public void setTaskId(Long taskId) { this.taskId = taskId; }
}
