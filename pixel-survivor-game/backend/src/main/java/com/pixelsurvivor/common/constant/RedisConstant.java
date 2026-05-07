package com.pixelsurvivor.common.constant;

/**
 * Redis Key 常量定义类
 * <p>统一管理所有Redis缓存Key的前缀，避免Key冲突，
 * 按业务模块分组：用户、商品、排行榜、好友、签到、分布式锁、布隆过滤器、限流</p>
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

    // ==================== 分布式锁 ====================
    /** 商品锁 */
    public static final String LOCK_SHOP_ITEM = "lock:shop:item:";
    /** 用户购买锁 */
    public static final String LOCK_USER_PURCHASE = "lock:user:purchase:";
    /** 签到锁 */
    public static final String LOCK_SIGN = "lock:sign:";

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