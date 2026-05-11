package com.pixelsurvivor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.pixelsurvivor.entity.CharacterDefinition;
import org.apache.ibatis.annotations.Mapper;

/**
 * 角色定义 Mapper
 */
@Mapper
public interface CharacterDefinitionMapper extends BaseMapper<CharacterDefinition> {
}