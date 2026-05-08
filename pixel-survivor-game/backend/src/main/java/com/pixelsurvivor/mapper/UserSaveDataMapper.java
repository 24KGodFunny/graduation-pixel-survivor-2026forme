package com.pixelsurvivor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.pixelsurvivor.entity.UserSaveData;
import org.apache.ibatis.annotations.Mapper;

/**
 * 用户全局存档 Mapper
 */
@Mapper
public interface UserSaveDataMapper extends BaseMapper<UserSaveData> {
}