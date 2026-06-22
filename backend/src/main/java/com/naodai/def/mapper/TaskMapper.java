package com.naodai.def.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.naodai.def.entity.Task;
import org.apache.ibatis.annotations.Mapper;

/**
 * 事项 Mapper
 */
@Mapper
public interface TaskMapper extends BaseMapper<Task> {
}
