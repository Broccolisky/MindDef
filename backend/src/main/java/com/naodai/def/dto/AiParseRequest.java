package com.naodai.def.dto;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * AI 文本解析请求 DTO
 */
@ApiModel("AI文本解析请求")
public class AiParseRequest {

    @NotBlank(message = "文本内容不能为空")
    @Size(max = 2000, message = "文本长度不能超过2000字")
    @ApiModelProperty(value = "待解析文本", example = "明天前写完实验报告，很重要", required = true)
    private String text;

    public String getText() { return text; }
    public void setText(String text) { this.text = text; }
}
