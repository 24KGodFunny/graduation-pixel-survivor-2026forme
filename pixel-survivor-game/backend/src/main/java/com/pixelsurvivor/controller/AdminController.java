package com.pixelsurvivor.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.pixelsurvivor.common.annotation.OperationLog;
import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.common.util.JwtUtil;
import com.pixelsurvivor.entity.*;
import com.pixelsurvivor.entity.vo.DailyStatsVO;
import com.pixelsurvivor.entity.vo.UserItemVO;
import com.pixelsurvivor.mapper.UserItemMapper;
import com.pixelsurvivor.service.AdminService;
import com.pixelsurvivor.service.ShopItemService;
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
    private final ShopItemService shopItemService;
    private final UserService userService;
    private final JwtUtil jwtUtil;
    private final UserItemMapper userItemMapper;

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
    @OperationLog(module = "管理员管理", operation = "CREATE", description = "注册新管理员")
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

    // ========== 商品管理 ==========

    @GetMapping("/shop/items")
    public Result<IPage<ShopItem>> getItems(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String type) {
        return Result.success(shopItemService.getShopItems(page, size, type));
    }

    @PostMapping("/shop/items")
    @OperationLog(module = "商品管理", operation = "CREATE", description = "新增商品")
    public Result<?> addItem(@RequestBody ShopItem item) {
        shopItemService.save(item);
        return Result.success("商品添加成功");
    }

    @PutMapping("/shop/items/{id}")
    @OperationLog(module = "商品管理", operation = "UPDATE", description = "更新商品")
    public Result<?> updateItem(@PathVariable Long id, @RequestBody ShopItem item) {
        item.setId(id);
        shopItemService.updateById(item);
        return Result.success("商品更新成功");
    }

    @DeleteMapping("/shop/items/{id}")
    @OperationLog(module = "商品管理", operation = "DELETE", description = "删除商品")
    public Result<?> deleteItem(@PathVariable Long id) {
        shopItemService.removeById(id);
        return Result.success("商品删除成功");
    }

    // ========== 用户管理 ==========

    @GetMapping("/users")
    public Result<IPage<User>> getUsers(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(userService.page(new Page<>(page, size)));
    }

    @PutMapping("/users/{id}/ban")
    @OperationLog(module = "用户管理", operation = "UPDATE", description = "封禁用户")
    public Result<?> banUser(@PathVariable Long id) {
        User user = userService.getById(id);
        user.setStatus(1);
        userService.updateById(user);
        return Result.success("用户已封禁");
    }

    @PutMapping("/users/{id}/unban")
    @OperationLog(module = "用户管理", operation = "UPDATE", description = "解封用户")
    public Result<?> unbanUser(@PathVariable Long id) {
        User user = userService.getById(id);
        user.setStatus(0);
        userService.updateById(user);
        return Result.success("用户已解封");
    }

    // ========== 用户背包管理 ==========

    /**
     * 查询用户背包物品（联表查询，支持按用户名/道具名搜索）
     */
    @GetMapping("/user-items")
    public Result<IPage<UserItemVO>> getUserItems(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String username,
            @RequestParam(required = false) String itemName) {
        Page<UserItemVO> pageParam = new Page<>(page, size);
        return Result.success(userItemMapper.selectUserItemPage(pageParam, username, itemName));
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
    @OperationLog(module = "管理员管理", operation = "DELETE", description = "删除管理员")
    public Result<?> deleteAdmin(@PathVariable Long id,
                                  @RequestAttribute Long adminId) {
        adminService.deleteAdmin(id, adminId);
        return Result.success("管理员删除成功");
    }

    /**
     * 修改密码
     */
    @PutMapping("/password")
    @OperationLog(module = "管理员管理", operation = "UPDATE", description = "修改密码")
    public Result<?> changePassword(@RequestAttribute Long adminId,
                                     @RequestBody Map<String, String> params) {
        String oldPassword = params.get("oldPassword");
        String newPassword = params.get("newPassword");
        adminService.changePassword(adminId, oldPassword, newPassword);
        return Result.success("密码修改成功");
    }

    // ========== 操作日志 ==========

    @GetMapping("/logs")
    public Result<IPage<AdminOperationLog>> getLogs(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(adminService.getOperationLogs(page, size));
    }

    // AdminController.java 中，在仪表盘相关方法区域添加

    @GetMapping("/dashboard/stats")
    public Result<Map<String, Object>> getDashboardStats() {
        return getDashboardOverview(); // 复用现有方法
    }

    @GetMapping("/dashboard/daily")
    public Result<List<DailyStatsVO>> getDaily(@RequestParam(defaultValue = "7d") String range) {
        return getDailyStats(range);   // 复用现有方法
    }
}