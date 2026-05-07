package com.pixelsurvivor.entity.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户背包物品 VO（管理后台联表查询用）
 */
@Data
public class UserItemVO {

    private Long id;
    private Long userId;
    private String username;
    private String itemCode;
    private String itemName;
    private String itemType;
    private Integer quantity;
    private Integer isEquipped;
    private LocalDateTime acquiredAt;
}