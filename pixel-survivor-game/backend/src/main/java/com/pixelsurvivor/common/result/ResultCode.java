package com.pixelsurvivor.common.result;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 统一错误码枚举
 * <p>定义系统中所有业务错误码及其对应的中文提示信息，
 * 错误码按业务模块分段：通用(200-500)、用户(1001-1099)、
 * 商城(2001-2099)、好友(3001-3099)、签到/任务(4001-4099)</p>
 *
 * @author PixelSurvivor
 */
@Getter
@AllArgsConstructor
public enum ResultCode {

    SUCCESS(200, "success"),
    BAD_REQUEST(400, "请求参数错误"),
    PARAM_ERROR(400, "参数错误"),
    UNAUTHORIZED(401, "未认证/Token过期"),
    FORBIDDEN(403, "无权限"),
    NOT_FOUND(404, "资源不存在"),
    INTERNAL_ERROR(500, "服务器内部错误"),
    TOO_MANY_REQUESTS(429, "请求过于频繁，请稍后再试"),

    // 用户相关 1001-1099
    USERNAME_EXISTS(1001, "用户名已存在"),
    USERNAME_OR_PASSWORD_ERROR(1002, "用户名或密码错误"),
    USER_BANNED(1003, "账号已被封禁"),
    USER_NOT_FOUND(1004, "用户不存在"),
    USER_DISABLED(1005, "账号已被禁用"),

    // 商城相关 2001-2099
    COIN_NOT_ENOUGH(2001, "游戏币不足"),
    DIAMOND_NOT_ENOUGH(2002, "钻石不足"),
    ITEM_OFF_SHELF(2003, "商品已下架"),
    STOCK_NOT_ENOUGH(2004, "库存不足"),
    BUY_LIMIT_EXCEEDED(2005, "超出限购数量"),

    // 好友相关 3001-3099
    FRIEND_REQUEST_SENT(3001, "好友请求已发送"),
    ALREADY_FRIENDS(3002, "已是好友"),

    // 签到/任务 4001-4099
    ALREADY_SIGNED(4001, "今日已签到"),
    TASK_NOT_COMPLETED(4002, "任务未完成"),
    TASK_REWARD_ALREADY_CLAIMED(4003, "任务奖励已领取"),

    // 背包/物品 5001-5099
    ITEM_NOT_ENOUGH(5001, "物品数量不足"),

    // 角色 6001-6099
    CHARACTER_ALREADY_UNLOCKED(6001, "角色已解锁"),
    CHARACTER_NOT_UNLOCKED(6002, "角色未解锁"),

    // 成就 7001-7099
    ACHIEVEMENT_NOT_COMPLETED(7001, "成就未完成"),
    ACHIEVEMENT_REWARD_ALREADY_CLAIMED(7002, "成就奖励已领取");

    private final int code;
    private final String message;
}