package com.naodai.def.dto;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;

/**
 * 任务列表查询 DTO
 */
@ApiModel("任务列表查询")
public class TaskListQuery {

    /** 按象限筛选，null 或 0 表示全部 */
    @ApiModelProperty(value = "象限筛选 null/0=全部", example = "1")
    private Integer quadrant;

    /** 按状态筛选，null 表示仅查待办/进行中 */
    @ApiModelProperty(value = "状态筛选", example = "0")
    private Integer status;

    public Integer getQuadrant() { return quadrant; }
    public void setQuadrant(Integer quadrant) { this.quadrant = quadrant; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
}
