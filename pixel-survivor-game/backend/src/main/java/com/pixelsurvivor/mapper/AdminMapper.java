package com.pixelsurvivor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.pixelsurvivor.entity.Admin;
import org.apache.ibatis.annotations.Mapper;

/**
 * 管理员表 Mapper 接口
 * <p>提供对 t_admin 表的基本 CRUD 操作，继承 MyBatis-Plus 的 BaseMapper</p>
 *
 * @author PixelSurvivor
 */
@Mapper
public interface AdminMapper extends BaseMapper<Admin> {
}
