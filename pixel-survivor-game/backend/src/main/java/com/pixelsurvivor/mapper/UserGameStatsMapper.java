package com.pixelsurvivor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.pixelsurvivor.entity.UserGameStats;
import org.apache.ibatis.annotations.Mapper;

/**
 * 用户游戏统计Mapper
 */
@Mapper
public interface UserGameStatsMapper extends BaseMapper<UserGameStats> {
}