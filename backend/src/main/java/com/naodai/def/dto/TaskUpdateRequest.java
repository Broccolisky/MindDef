package com.naodai.def.dto;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;

import javax.validation.constraints.*;

/**
 * 任务编辑请求 DTO
 */
@ApiModel("编辑任务请求")
public class TaskUpdateRequest {

    @NotBlank(message = "事项内容不能为空")
    @Size(max = 256, message = "事项内容不超过256字")
    @ApiModelProperty(value = "事项内容", example = "更新后的内容", required = true)
    private String content;

    @Min(value = 0, message = "重要性须0-100")
    @Max(value = 100, message = "重要性须0-100")
    @ApiModelProperty(value = "重要性 0-100", example = "80")
    private Integer importance;

    @Min(value = 0, message = "紧急性须0-100")
    @Max(value = 100, message = "紧急性须0-100")
    @ApiModelProperty(value = "紧急性 0-100", example = "70")
    private Integer urgency;

    @ApiModelProperty(value = "截止日期 yyyy-MM-dd")
    private String deadline;

    @ApiModelProperty(value = "来源 1手动/2AI/3引导")
    private Integer source;

    @ApiModelProperty(value = "重复模式 0:不重复 1:每日 2:仅工作日 3:仅休息日")
    private Integer repeatMode;

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
