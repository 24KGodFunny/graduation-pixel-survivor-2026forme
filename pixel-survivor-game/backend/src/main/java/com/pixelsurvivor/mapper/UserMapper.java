package com.pixelsurvivor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.pixelsurvivor.entity.User;
import org.apache.ibatis.annotations.Mapper;

/**
 * 用户表 Mapper 接口
 * <p>提供对 t_user 表的基本 CRUD 操作，继承 MyBatis-Plus 的 BaseMapper</p>
 *
 * @author PixelSurvivor
 */
@Mapper
public interface UserMapper extends BaseMapper<User> {
}
