package com.pixelsurvivor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.pixelsurvivor.entity.Ranking;
import org.apache.ibatis.annotations.Mapper;

/**
 * 排行榜Mapper
 */
@Mapper
public interface RankingMapper extends BaseMapper<Ranking> {
}