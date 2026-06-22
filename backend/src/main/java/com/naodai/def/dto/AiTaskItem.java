package com.naodai.def.dto;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;

/**
 * AI 解析出的单条事项
 */
@ApiModel("AI解析事项项")
public class AiTaskItem {

    /** 事项内容 */
    @ApiModelProperty("事项内容")
    private String content;

    /** 重要性 0-100 */
    @ApiModelProperty("重要性 0-100")
    private Integer importance;

    /** 紧急性 0-100 */
    @ApiModelProperty("紧急性 0-100")
    private Integer urgency;

    /** 截止日期 yyyy-MM-dd */
    @ApiModelProperty("截止日期")
    private String deadline;

    /** 解析出的象限 */
    @ApiModelProperty("解析出的象限 1-4")
    private Integer quadrant;

    /** 建议文案 */
    @ApiModelProperty("建议文案")
    private String advice;

    // ── Getter / Setter ──

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public Integer getImportance() { return importance; }
    public void setImportance(Integer importance) { this.importance = importance; }

    public Integer getUrgency() { return urgency; }
    public void setUrgency(Integer urgency) { this.urgency = urgency; }

    public String getDeadline() { return deadline; }
    public void setDeadline(String deadline) { this.deadline = deadline; }

    public Integer getQuadrant() { return quadrant; }
    public void setQuadrant(Integer quadrant) { this.quadrant = quadrant; }

    public String getAdvice() { return advice; }
    public void setAdvice(String advice) { this.advice = advice; }
}
