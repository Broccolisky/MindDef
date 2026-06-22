package com.naodai.def.dto;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * 任务编辑请求 DTO
 */
@ApiModel("编辑任务请求")
public class TaskUpdateRequest {

    @NotBlank(message = "事项内容不能为空")
    @Size(max = 256, message = "事项内容不超过256字")
    @ApiModelProperty(value = "事项内容", example = "更新后的内容", required = true)
    private String content;

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
}
