package com.pixelsurvivor.entity.vo;

import lombok.Data;

import java.io.Serializable;

/**
 * 每日统计 VO
 */
@Data
public class DailyStatsVO implements Serializable {
    private static final long serialVersionUID = 1L;
    /** 日期 (yyyy-MM-dd) */
    private String date;
    /** 新增用户数 */
    private Long newUsers;
    /** 新增订单数 */
    private Long newOrders;
    /** 收入金额 */
    private Integer revenue;
}