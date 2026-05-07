package com.pixelsurvivor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.pixelsurvivor.entity.Friend;
import org.apache.ibatis.annotations.Mapper;

/**
 * 好友关系表 Mapper 接口
 * <p>提供对 t_friend 表的基本 CRUD 操作，继承 MyBatis-Plus 的 BaseMapper</p>
 *
 * @author PixelSurvivor
 */
@Mapper
public interface FriendMapper extends BaseMapper<Friend> {
}
