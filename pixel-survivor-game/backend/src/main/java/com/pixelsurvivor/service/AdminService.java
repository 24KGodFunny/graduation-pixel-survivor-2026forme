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
     * 获取操作日志(分页)
     */
    IPage<AdminOperationLog> getOperationLogs(int page, int size);

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
}
