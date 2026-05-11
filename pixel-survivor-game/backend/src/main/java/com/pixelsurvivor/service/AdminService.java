package com.pixelsurvivor.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.pixelsurvivor.entity.Admin;
import com.pixelsurvivor.entity.AdminOperationLog;
import com.pixelsurvivor.entity.vo.DailyStatsVO;

import java.util.List;
import java.util.Map;

/**
 * 管理员服务接口
 * <p>定义管理员登录、操作日志查询等业务方法</p>
 *
 * @author PixelSurvivor
 */
public interface AdminService extends IService<Admin> {

    /**
     * 管理员登录
     */
    Admin login(String username, String password);

    /**
     * 获取操作日志(分页+筛选)
     */
    IPage<AdminOperationLog> getOperationLogs(int page, int size,
                                               String adminUsername, String module,
                                               String startDate, String endDate);

    /**
     * 注册新管理员
     *
     * @param username 用户名
     * @param password 密码（明文，服务层会进行BCrypt加密）
     * @param role     角色（SUPER_ADMIN / ADMIN）
     * @return 注册成功的管理员对象
     */
    Admin register(String username, String password, String role);

    /**
     * 获取管理员列表（分页）
     */
    IPage<Admin> getAdminList(int page, int size);

    /**
     * 删除管理员
     */
    void deleteAdmin(Long id, Long currentAdminId);

    /**
     * 修改密码
     */
    void changePassword(Long adminId, String oldPassword, String newPassword);

    /**
     * 获取每日统计数据
     *
     * @param range 时间范围：7d / 30d / 3m / 6m
     * @return 每日统计列表
     */
    List<DailyStatsVO> getDailyStats(String range);

    /**
     * 获取仪表盘概览数据
     */
    Map<String, Object> getDashboardOverview();

    /**
     * 获取用户详情（含地图进度）
     */
    Map<String, Object> getUserDetail(Long userId);

    /**
     * 根据用户名获取用户详情（含地图进度、游戏统计、背包物品）
     */
    Map<String, Object> getUserDetailByUsername(String username);

    /**
     * 更新用户基本信息（昵称等，来自 t_user 表）
     */
    void updateUser(Long userId, Map<String, Object> params);

    /**
     * 更新用户存档数据（金币、钻石、角色、地图、成就等，操作 t_user_save_data 的 JSON）
     */
    void updateSaveData(Long userId, Map<String, Object> params);

    /**
     * 删除用户及其所有关联数据
     */
    void deleteUserCompletely(Long userId);
}
