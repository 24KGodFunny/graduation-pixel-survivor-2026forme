package com.pixelsurvivor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.pixelsurvivor.entity.GameRecord;
import org.apache.ibatis.annotations.Mapper;

/**
 * 游戏记录表 Mapper 接口
 * <p>提供对 t_game_record 表的基本 CRUD 操作，继承 MyBatis-Plus 的 BaseMapper</p>
 *
 * @author PixelSurvivor
 */
@Mapper
public interface GameRecordMapper extends BaseMapper<GameRecord> {
}
