package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 商品实体（仅存运营数据，商品详情由游戏客户端资源定义）
 * <p>item_code 对应游戏客户端 shop_items.json 中的 id 字段</p>
 */
@Data
@TableName("t_shop_item")
public class ShopItem {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 商品编码，对应游戏客户端资源ID，如 item_heal_potion */
    private String itemCode;

    /** 游戏币价格(0表示不可用游戏币购买) */
    private Integer priceCoin;

    /** 钻石价格(0表示不可用钻石购买) */
    private Integer priceDiamond;

    /** 库存(-1为无限) */
    private Integer stock;

    /** 每人限购(-1为无限) */
    private Integer maxBuyCount;

    /** 状态: 1上架 0下架 */
    private Integer status;

    /** 排序权重 */
    private Integer sortOrder;

    /** 上架开始时间(NULL=永久) */
    private LocalDateTime startTime;

    /** 上架结束时间(NULL=永久) */
    private LocalDateTime endTime;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}