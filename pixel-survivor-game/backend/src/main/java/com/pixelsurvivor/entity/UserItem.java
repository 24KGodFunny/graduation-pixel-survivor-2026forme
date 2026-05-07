package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户背包实体
 * <p>item_code 对应游戏客户端资源中的物品ID</p>
 */
@Data
@TableName("t_user_item")
public class UserItem {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    /** 商品编码，对应游戏客户端资源ID */
    private String itemCode;

    /** 数量 */
    private Integer quantity;

    /** 是否已装备 */
    private Integer isEquipped;

    private LocalDateTime acquiredAt;

    private LocalDateTime updatedAt;
}