package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 充值记录实体
 */
@Data
@TableName("t_recharge_record")
public class RechargeRecord {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 充值订单号 */
    private String orderNo;

    private Long userId;

    /** 金额(元) */
    private BigDecimal amount;

    /** 获得钻石 */
    private Integer diamondCount;

    /** 赠送钻石 */
    private Integer bonusDiamond;

    /** 状态: 0待支付 1成功 2失败 */
    private Integer status;

    /** 支付渠道: alipay/wechat */
    private String payChannel;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}