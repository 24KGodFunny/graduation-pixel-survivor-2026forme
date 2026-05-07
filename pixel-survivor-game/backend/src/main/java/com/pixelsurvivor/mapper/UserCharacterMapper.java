package com.pixelsurvivor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.pixelsurvivor.entity.UserCharacter;
import org.apache.ibatis.annotations.Mapper;

/**
 * 用户角色Mapper
 */
@Mapper
public interface UserCharacterMapper extends BaseMapper<UserCharacter> {
}