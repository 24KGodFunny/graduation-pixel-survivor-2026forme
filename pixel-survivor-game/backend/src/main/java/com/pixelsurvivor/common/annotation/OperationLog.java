package com.pixelsurvivor.common.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 管理员操作日志注解
 * <p>标记在Controller方法上，配合 {@link com.pixelsurvivor.common.aspect.OperationLogAspect}
 * 切面自动记录管理员的操作行为（如新增商品、封禁用户等）到 admin_operation_log 表</p>
 *
 * @author PixelSurvivor
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface OperationLog {

    /** 操作模块 */
    String module() default "";

    /** 操作类型: CREATE, UPDATE, DELETE, LOGIN, etc. */
    String operation() default "";

    /** 操作描述 */
    String description() default "";
}