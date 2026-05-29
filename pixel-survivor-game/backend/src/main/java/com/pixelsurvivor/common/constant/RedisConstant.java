package com.pixelsurvivor.common.constant;

/**
 * Redis Key 常量定义类
 * <p>统一管理所有Redis缓存Key的前缀，避免Key冲突</p>
 *
 * 面试重点 - Key 命名规范:
 *   使用冒号分隔的层级结构，如 "user:info:123" 表示用户 ID=123 的信息缓存。
 *   好处：(1)可读性强 (2)支持 Redis 的 KEYS/MATCH 模糊查询 (3)方便按前缀批量管理
 *
 * 面试注意:
 *   下面的常量分为"已使用"和"预留未使用"两类。商城/好友/签到/排行榜/成就等功能
 *   在数据库设计中预留了表结构，但后端 API 尚未实现。面试时如果被问到，可以说明
 *   "这是为未来功能预留的设计"，展示前瞻性思维。
 *
 * @author PixelSurvivor
 */
public class RedisConstant {

    private RedisConstant() {}

    // ==================== 用户 ====================
    /** 用户信息 Hash */
    public static final String USER_INFO = "user:info:";
    /** 用户Token */
    public static final String USER_TOKEN = "user:token:";
    /** 在线用户集合 */
    public static final String USER_ONLINE = "user:online";

    // ==================== 商品 ====================
    /** 商品列表缓存 */
    public static final String SHOP_ITEMS_LIST = "shop:items:list";
    /** 商品详情缓存 */
    public static final String SHOP_ITEM_DETAIL = "shop:item:";
    /** 按类型商品列表 */
    public static final String SHOP_ITEMS_TYPE = "shop:items:type:";

    // ==================== 排行榜 ====================
    /** 排行榜 Sorted Set */
    public static final String RANKING = "ranking:";

    // ==================== 好友 ====================
    /** 好友列表 */
    public static final String FRIEND_LIST = "friend:list:";

    // ==================== 签到 ====================
    /** 签到记录 Bitmap */
    public static final String SIGN_RECORD = "sign:record:";

    // ==================== 仪表盘 ====================
    /** 仪表盘概览缓存 */
    public static final String DASHBOARD_OVERVIEW = "dashboard:overview";
    /** 每日统计缓存 */
    public static final String DASHBOARD_DAILY = "dashboard:daily:";

    // ==================== 分布式锁 ====================
    /** 商品锁 */
    public static final String LOCK_SHOP_ITEM = "lock:shop:item:";
    /** 用户购买锁 */
    public static final String LOCK_USER_PURCHASE = "lock:user:purchase:";
    /** 签到锁 */
    public static final String LOCK_SIGN = "lock:sign:";
    /** 同步上传锁 */
    public static final String LOCK_SYNC_UPLOAD = "lock:sync:upload:";

    // ==================== 布隆过滤器 ====================
    public static final String BLOOM_USER_ID = "bloom:user:id";
    public static final String BLOOM_SHOP_ITEM_ID = "bloom:shop:item:id";

    // ==================== 限流 ====================
    /** API限流 */
    public static final String RATE_API = "rate:api:";
    /** 购买限流 */
    public static final String RATE_PURCHASE = "rate:purchase:";

    // ==================== 缓存逻辑过期标记 ====================
    public static final String CACHE_LOGICAL_EXPIRE = "cache:logical:expire:";
}