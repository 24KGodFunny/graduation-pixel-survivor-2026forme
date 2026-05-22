package com.pixelsurvivor.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.pixelsurvivor.common.annotation.OperationLog;
import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.common.util.JwtUtil;
import com.pixelsurvivor.entity.*;
import com.pixelsurvivor.entity.vo.DailyStatsVO;
import com.pixelsurvivor.service.AdminService;
import com.pixelsurvivor.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 管理后台 - 管理员控制器
 * <p>处理管理员登录、商品CRUD管理、用户封禁/解封、
 * 操作日志查询等管理后台请求，敏感操作通过 @OperationLog 注解自动记录</p>
 *
 * @author PixelSurvivor
 */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final UserService userService;
    private final JwtUtil jwtUtil;

    /**
     * 管理员登录
     * 验证用户名密码，返回 JWT Token 和管理员信息
     */
    @PostMapping("/login")
    public Result<?> login(@RequestBody Map<String, String> params) {
        String username = params.get("username");
        String password = params.get("password");
        Admin admin = adminService.login(username, password);
        String token = jwtUtil.generateAdminToken(admin.getId(), admin.getUsername(), admin.getRole());
        Map<String, Object> data = new HashMap<>();
        data.put("token", token);
        data.put("adminId", admin.getId());
        data.put("username", admin.getUsername());
        data.put("role", admin.getRole());
        return Result.success(data);
    }

    /**
     * 注册新管理员
     */
    @PostMapping("/register")
    @OperationLog(module = "管理员管理", operation = "新增", description = "注册新管理员")
    public Result<?> register(@RequestBody Map<String, String> params) {
        String username = params.get("username");
        String password = params.get("password");
        String role = params.getOrDefault("role", "ADMIN");
        Admin admin = adminService.register(username, password, role);
        return Result.success(admin);
    }

    // ========== 仪表盘 ==========

    /**
     * 获取仪表盘概览数据
     */
    @GetMapping("/dashboard/overview")
    public Result<Map<String, Object>> getDashboardOverview() {
        return Result.success(adminService.getDashboardOverview());
    }

    /**
     * 获取每日统计数据（支持 7d/30d/3m/6m 范围）
     */
    @GetMapping("/dashboard/daily-stats")
    public Result<List<DailyStatsVO>> getDailyStats(
            @RequestParam(defaultValue = "7d") String range) {
        return Result.success(adminService.getDailyStats(range));
    }

    // ========== 用户管理 ==========

    /**
     * 分页获取用户列表
     */
    @GetMapping("/users")
    public Result<IPage<User>> getUsers(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(userService.page(new Page<>(page, size)));
    }

    /**
     * 封禁用户：将用户状态置为 1（封禁）
     */
    @PutMapping("/users/{id}/ban")
    @OperationLog(module = "用户管理", operation = "封禁", description = "封禁用户")
    public Result<?> banUser(@PathVariable Long id) {
        User user = userService.getById(id);
        user.setStatus(1);
        userService.updateById(user);
        return Result.success("用户已封禁");
    }

    /**
     * 解封用户：将用户状态置为 0（正常）
     */
    @PutMapping("/users/{id}/unban")
    @OperationLog(module = "用户管理", operation = "解封", description = "解封用户")
    public Result<?> unbanUser(@PathVariable Long id) {
        User user = userService.getById(id);
        user.setStatus(0);
        userService.updateById(user);
        return Result.success("用户已解封");
    }

    // ========== 管理员管理 ==========

    /**
     * 获取管理员列表
     */
    @GetMapping("/admins")
    public Result<IPage<Admin>> getAdmins(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(adminService.getAdminList(page, size));
    }

    /**
     * 删除管理员
     */
    @DeleteMapping("/admins/{id}")
    @OperationLog(module = "管理员管理", operation = "删除", description = "删除管理员")
    public Result<?> deleteAdmin(@PathVariable Long id,
                                  @RequestAttribute Long adminId) {
        adminService.deleteAdmin(id, adminId);
        return Result.success("管理员删除成功");
    }

    /**
     * 修改密码
     */
    @PutMapping("/password")
    @OperationLog(module = "管理员管理", operation = "修改", description = "修改密码")
    public Result<?> changePassword(@RequestAttribute Long adminId,
                                     @RequestBody Map<String, String> params) {
        String oldPassword = params.get("oldPassword");
        String newPassword = params.get("newPassword");
        adminService.changePassword(adminId, oldPassword, newPassword);
        return Result.success("密码修改成功");
    }

    // ========== 操作日志 ==========

    /**
     * 分页查询操作日志，支持按管理员用户名、模块、日期范围筛选
     */
    @GetMapping("/logs")
    public Result<IPage<AdminOperationLog>> getLogs(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String adminUsername,
            @RequestParam(required = false) String module,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate) {
        return Result.success(adminService.getOperationLogs(page, size, adminUsername, module, startDate, endDate));
    }

    // AdminController.java 中，在仪表盘相关方法区域添加

    /**
     * 仪表盘统计数据（前端兼容接口，复用 getDashboardOverview）
     */
    @GetMapping("/dashboard/stats")
    public Result<Map<String, Object>> getDashboardStats() {
        return getDashboardOverview();
    }

    /**
     * 每日趋势数据（前端兼容接口，复用 getDailyStats）
     */
    @GetMapping("/dashboard/daily")
    public Result<List<DailyStatsVO>> getDaily(@RequestParam(defaultValue = "7d") String range) {
        return getDailyStats(range);
    }

    // ==================== 用户数据管理 ====================

    /**
     * 根据用户名获取用户详情（含地图进度、游戏统计）
     * 注意：此路径必须在 /users/{userId}/detail 之前，否则会被路径变量匹配
     */
    @GetMapping("/users/detail-by-username")
    public Result<Map<String, Object>> getUserDetailByUsername(@RequestParam String username) {
        return Result.success(adminService.getUserDetailByUsername(username));
    }

    /**
     * 获取用户详情（含地图进度、游戏统计）
     */
    @GetMapping("/users/{userId}/detail")
    public Result<Map<String, Object>> getUserDetail(@PathVariable Long userId) {
        return Result.success(adminService.getUserDetail(userId));
    }

    /**
     * 更新用户基本信息（昵称等，来自 t_user 表）
     */
    @PutMapping("/users/{userId}")
    @OperationLog(module = "用户数据管理", operation = "修改", description = "编辑用户信息")
    public Result<Void> updateUser(@PathVariable Long userId, @RequestBody Map<String, Object> params) {
        adminService.updateUser(userId, params);
        return Result.success();
    }

    /**
     * 更新用户存档数据（金币、钻石、角色、地图、成就等，操作 t_user_save_data 的 JSON）
     */
    @PutMapping("/users/{userId}/save-data")
    @OperationLog(module = "用户数据管理", operation = "修改", description = "编辑用户存档数据")
    public Result<Void> updateSaveData(@PathVariable Long userId, @RequestBody Map<String, Object> params) {
        adminService.updateSaveData(userId, params);
        return Result.success();
    }

    /**
     * 删除用户及其所有关联数据
     */
    @DeleteMapping("/users/{userId}")
    @OperationLog(module = "用户数据管理", operation = "删除", description = "删除用户及其所有关联数据")
    public Result<Void> deleteUser(@PathVariable Long userId) {
        adminService.deleteUserCompletely(userId);
        return Result.success();
    }
}
