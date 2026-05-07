package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 购买记录实体
 */
@Data
@TableName("t_purchase_record")
public class PurchaseRecord {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 订单号 */
    private String orderNo;

    private Long userId;

    /** 商品编码，对应游戏客户端资源ID */
    private String itemCode;

    /** 商品名(冗余，方便后台查看) */
    private String itemName;

    /** 购买数量 */
    private Integer quantity;

    /** 总价 */
    private Integer totalPrice;

    /** 支付类型: 1游戏币 2钻石 */
    private Integer payType;

    /** 状态: 0待支付 1成功 2失败 3退款 */
    private Integer status;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}