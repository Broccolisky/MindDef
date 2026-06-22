package com.naodai.def.dto;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;

import javax.validation.constraints.Max;
import javax.validation.constraints.Min;
import javax.validation.constraints.NotNull;

/**
 * 移动象限请求 DTO
 */
@ApiModel("移动象限请求")
public class QuadrantMoveRequest {

    @NotNull(message = "象限值不能为空")
    @Min(value = 1, message = "象限值须1-4")
    @Max(value = 4, message = "象限值须1-4")
    @ApiModelProperty(value = "目标象限 1-4", example = "2", required = true)
    private Integer quadrant;

    public Integer getQuadrant() { return quadrant; }
    public void setQuadrant(Integer quadrant) { this.quadrant = quadrant; }
}
