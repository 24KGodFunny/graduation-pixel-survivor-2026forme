package com.pixelsurvivor.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.pixelsurvivor.common.exception.BusinessException;
import com.pixelsurvivor.common.result.ResultCode;
import com.pixelsurvivor.entity.*;
import com.pixelsurvivor.entity.vo.DailyStatsVO;
import com.pixelsurvivor.mapper.*;
import com.pixelsurvivor.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 管理员服务实现类
 * <p>实现管理员登录认证、操作日志分页查询等业务逻辑，
 * 使用 BCrypt 进行密码校验</p>
 *
 * @author PixelSurvivor
 */
@Service
@RequiredArgsConstructor
public class AdminServiceImpl extends ServiceImpl<AdminMapper, Admin> implements AdminService {

    private final AdminOperationLogMapper adminOperationLogMapper;
    private final PasswordEncoder passwordEncoder;
    private final UserMapper userMapper;
    private final PurchaseRecordMapper purchaseRecordMapper;

    @Override
    public Admin login(String username, String password) {
        LambdaQueryWrapper<Admin> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Admin::getUsername, username);
        Admin admin = this.getOne(wrapper);
        if (admin == null || !passwordEncoder.matches(password, admin.getPassword())) {
            throw new BusinessException(ResultCode.USERNAME_OR_PASSWORD_ERROR);
        }
        return admin;
    }

    @Override
    public IPage<AdminOperationLog> getOperationLogs(int page, int size) {
        Page<AdminOperationLog> pageParam = new Page<>(page, size);
        LambdaQueryWrapper<AdminOperationLog> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByDesc(AdminOperationLog::getCreatedAt);
        return adminOperationLogMapper.selectPage(pageParam, wrapper);
    }

    @Override
    public Admin register(String username, String password, String role) {
        // 检查用户名是否已存在
        LambdaQueryWrapper<Admin> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Admin::getUsername, username);
        if (this.count(wrapper) > 0) {
            throw new BusinessException(ResultCode.USERNAME_EXISTS);
        }

        // 创建管理员对象
        Admin admin = new Admin();
        admin.setUsername(username);
        admin.setPassword(passwordEncoder.encode(password));
        admin.setRole(role);
        admin.setStatus(1);
        admin.setCreatedAt(LocalDateTime.now());

        // 保存到数据库
        this.save(admin);

        // 返回时清除密码字段，避免泄露
        admin.setPassword(null);
        return admin;
    }

    @Override
    public IPage<Admin> getAdminList(int page, int size) {
        Page<Admin> pageParam = new Page<>(page, size);
        LambdaQueryWrapper<Admin> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByDesc(Admin::getCreatedAt);
        IPage<Admin> result = this.page(pageParam, wrapper);
        // 清除密码字段
        result.getRecords().forEach(a -> a.setPassword(null));
        return result;
    }

    @Override
    public void deleteAdmin(Long id, Long currentAdminId) {
        if (id.equals(currentAdminId)) {
            throw new BusinessException(ResultCode.PARAM_ERROR, "不能删除自己");
        }
        Admin admin = this.getById(id);
        if (admin == null) {
            throw new BusinessException(ResultCode.PARAM_ERROR, "管理员不存在");
        }
        if ("SUPER_ADMIN".equals(admin.getRole())) {
            throw new BusinessException(ResultCode.PARAM_ERROR, "不能删除超级管理员");
        }
        this.removeById(id);
    }

    @Override
    public void changePassword(Long adminId, String oldPassword, String newPassword) {
        Admin admin = this.getById(adminId);
        if (admin == null) {
            throw new BusinessException(ResultCode.PARAM_ERROR, "管理员不存在");
        }
        if (!passwordEncoder.matches(oldPassword, admin.getPassword())) {
            throw new BusinessException(ResultCode.PARAM_ERROR, "原密码错误");
        }
        admin.setPassword(passwordEncoder.encode(newPassword));
        this.updateById(admin);
    }

    @Override
    public List<DailyStatsVO> getDailyStats(String range) {
        // 计算日期范围
        LocalDate endDate = LocalDate.now();
        LocalDate startDate;
        switch (range) {
            case "30d":
                startDate = endDate.minusDays(30);
                break;
            case "3m":
                startDate = endDate.minusMonths(3);
                break;
            case "6m":
                startDate = endDate.minusMonths(6);
                break;
            case "7d":
            default:
                startDate = endDate.minusDays(7);
                break;
        }

        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");

        // 查询用户注册数据（按天分组）
        LambdaQueryWrapper<User> userWrapper = new LambdaQueryWrapper<>();
        userWrapper.ge(User::getCreatedAt, LocalDateTime.of(startDate, LocalTime.MIN))
                   .le(User::getCreatedAt, LocalDateTime.of(endDate, LocalTime.MAX));
        List<User> users = userMapper.selectList(userWrapper);
        Map<String, Long> userCountByDate = users.stream()
                .collect(Collectors.groupingBy(
                        u -> u.getCreatedAt().toLocalDate().format(formatter),
                        Collectors.counting()));

        // 查询购买记录数据（按天分组）
        LambdaQueryWrapper<PurchaseRecord> prWrapper = new LambdaQueryWrapper<>();
        prWrapper.ge(PurchaseRecord::getCreatedAt, LocalDateTime.of(startDate, LocalTime.MIN))
                 .le(PurchaseRecord::getCreatedAt, LocalDateTime.of(endDate, LocalTime.MAX));
        List<PurchaseRecord> purchases = purchaseRecordMapper.selectList(prWrapper);
        Map<String, List<PurchaseRecord>> purchaseByDate = purchases.stream()
                .collect(Collectors.groupingBy(
                        p -> p.getCreatedAt().toLocalDate().format(formatter)));

        // 组装每日统计数据
        List<DailyStatsVO> stats = new ArrayList<>();
        LocalDate current = startDate;
        while (!current.isAfter(endDate)) {
            String dateStr = current.format(formatter);
            DailyStatsVO vo = new DailyStatsVO();
            vo.setDate(dateStr);
            vo.setNewUsers(userCountByDate.getOrDefault(dateStr, 0L));

            List<PurchaseRecord> dayPurchases = purchaseByDate.getOrDefault(dateStr, Collections.emptyList());
            vo.setNewOrders((long) dayPurchases.size());
            vo.setRevenue(dayPurchases.stream()
                    .map(PurchaseRecord::getTotalPrice)
                    .reduce(0, Integer::sum));

            stats.add(vo);
            current = current.plusDays(1);
        }
        return stats;
    }

    @Override
    public Map<String, Object> getDashboardOverview() {
        Map<String, Object> overview = new HashMap<>();

        // 总用户数
        overview.put("totalUsers", userMapper.selectCount(null));

        // 总订单数
        overview.put("totalOrders", purchaseRecordMapper.selectCount(null));

        // 总收入
        LambdaQueryWrapper<PurchaseRecord> allWrapper = new LambdaQueryWrapper<>();
        allWrapper.eq(PurchaseRecord::getStatus, 1);
        List<PurchaseRecord> allPurchases = purchaseRecordMapper.selectList(allWrapper);
        Integer totalRevenue = allPurchases.stream()
                .map(PurchaseRecord::getTotalPrice)
                .reduce(0, Integer::sum);
        overview.put("totalRevenue", totalRevenue);

        // 今日新增用户
        LocalDateTime todayStart = LocalDateTime.of(LocalDate.now(), LocalTime.MIN);
        LocalDateTime todayEnd = LocalDateTime.of(LocalDate.now(), LocalTime.MAX);
        LambdaQueryWrapper<User> todayUserWrapper = new LambdaQueryWrapper<>();
        todayUserWrapper.ge(User::getCreatedAt, todayStart)
                        .le(User::getCreatedAt, todayEnd);
        overview.put("todayNewUsers", userMapper.selectCount(todayUserWrapper));

        // 今日订单数
        LambdaQueryWrapper<PurchaseRecord> todayOrderWrapper = new LambdaQueryWrapper<>();
        todayOrderWrapper.ge(PurchaseRecord::getCreatedAt, todayStart)
                         .le(PurchaseRecord::getCreatedAt, todayEnd);
        overview.put("todayOrders", purchaseRecordMapper.selectCount(todayOrderWrapper));

        // 今日收入
        List<PurchaseRecord> todayPurchases = purchaseRecordMapper.selectList(todayOrderWrapper);
        Integer todayRevenue = todayPurchases.stream()
                .map(PurchaseRecord::getTotalPrice)
                .reduce(0, Integer::sum);
        overview.put("todayRevenue", todayRevenue);

        return overview;
    }
}