package com.pixelsurvivor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.pixelsurvivor.entity.UserItem;
import com.pixelsurvivor.entity.vo.UserItemVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 用户背包物品表 Mapper 接口
 * <p>提供对 t_user_item 表的基本 CRUD 操作，继承 MyBatis-Plus 的 BaseMapper</p>
 *
 * @author PixelSurvivor
 */
@Mapper
public interface UserItemMapper extends BaseMapper<UserItem> {

    /**
     * 联表分页查询用户背包（带用户名/道具名搜索）
     */
    IPage<UserItemVO> selectUserItemPage(Page<UserItemVO> page,
                                          @Param("username") String username,
                                          @Param("itemName") String itemName);
}
