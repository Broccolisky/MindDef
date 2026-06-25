package com.naodai.def.dto;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;

import javax.validation.constraints.*;

/**
 * 任务创建请求 DTO（手动/引导共用）
 */
@ApiModel("创建任务请求")
public class TaskCreateRequest {

    @NotBlank(message = "事项内容不能为空")
    @Size(max = 256, message = "事项内容不超过256字")
    @ApiModelProperty(value = "事项内容", example = "完成期末报告", required = true)
    private String content;

    @NotNull(message = "重要性不能为空")
    @Min(value = 0, message = "重要性须0-100")
    @Max(value = 100, message = "重要性须0-100")
    @ApiModelProperty(value = "重要性 0-100", example = "80", required = true)
    private Integer importance;

    @NotNull(message = "紧急性不能为空")
    @Min(value = 0, message = "紧急性须0-100")
    @Max(value = 100, message = "紧急性须0-100")
    @ApiModelProperty(value = "紧急性 0-100", example = "70", required = true)
    private Integer urgency;

    /** 截止日期（可选） */
    @ApiModelProperty(value = "截止日期 yyyy-MM-dd", example = "2026-06-30")
    private String deadline;

    /** 来源 1:手动 2:AI识别 3:引导，默认 1 */
    @ApiModelProperty(value = "来源 1手动/2AI/3引导", example = "1")
    private Integer source = 1;

    /** 重复模式 0:不重复 1:每日 2:仅工作日 3:仅休息日 */
    @ApiModelProperty(value = "重复模式 0:不重复 1:每日 2:仅工作日 3:仅休息日", example = "0")
    private Integer repeatMode = 0;

    // ── Getter / Setter ──

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public Integer getImportance() { return importance; }
    public void setImportance(Integer importance) { this.importance = importance; }

    public Integer getUrgency() { return urgency; }
    public void setUrgency(Integer urgency) { this.urgency = urgency; }

    public String getDeadline() { return deadline; }
    public void setDeadline(String deadline) { this.deadline = deadline; }

    public Integer getSource() { return source; }
    public void setSource(Integer source) { this.source = source; }

    public Integer getRepeatMode() { return repeatMode; }
    public void setRepeatMode(Integer repeatMode) { this.repeatMode = repeatMode; }
}
