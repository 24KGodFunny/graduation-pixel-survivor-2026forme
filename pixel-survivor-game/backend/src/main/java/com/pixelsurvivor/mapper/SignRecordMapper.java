package com.pixelsurvivor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.pixelsurvivor.entity.SignRecord;
import org.apache.ibatis.annotations.Mapper;

/**
 * 签到记录表 Mapper 接口
 * <p>提供对 t_sign_record 表的基本 CRUD 操作，继承 MyBatis-Plus 的 BaseMapper</p>
 *
 * @author PixelSurvivor
 */
@Mapper
public interface SignRecordMapper extends BaseMapper<SignRecord> {
}
