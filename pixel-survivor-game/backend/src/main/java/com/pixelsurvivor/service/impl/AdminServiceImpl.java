package com.pixelsurvivor.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pixelsurvivor.common.exception.BusinessException;
import com.pixelsurvivor.common.result.ResultCode;
import com.pixelsurvivor.entity.Admin;
import com.pixelsurvivor.entity.AdminOperationLog;
import com.pixelsurvivor.entity.CharacterDefinition;
import com.pixelsurvivor.entity.MapDefinition;
import com.pixelsurvivor.entity.User;
import com.pixelsurvivor.entity.UserSaveData;
import com.pixelsurvivor.entity.vo.DailyStatsVO;
import com.pixelsurvivor.mapper.AdminMapper;
import com.pixelsurvivor.mapper.AdminOperationLogMapper;
import com.pixelsurvivor.mapper.CharacterDefinitionMapper;
import com.pixelsurvivor.mapper.MapDefinitionMapper;
import com.pixelsurvivor.mapper.UserMapper;
import com.pixelsurvivor.mapper.UserSaveDataMapper;
import com.pixelsurvivor.service.AdminService;
import com.pixelsurvivor.service.UserService;
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
    private final UserSaveDataMapper userSaveDataMapper;
    private final MapDefinitionMapper mapDefinitionMapper;
    private final CharacterDefinitionMapper characterDefinitionMapper;
    private final UserService userService;
    private final ObjectMapper objectMapper;

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
    public IPage<AdminOperationLog> getOperationLogs(int page, int size,
                                                      String adminUsername, String module,
                                                      String startDate, String endDate) {
        QueryWrapper<AdminOperationLog> qw = new QueryWrapper<>();
        if (adminUsername != null && !adminUsername.isEmpty()) {
            qw.like("admin_username", adminUsername);
        }
        if (module != null && !module.isEmpty()) {
            qw.eq("module", module);
        }
        if (startDate != null && !startDate.isEmpty()) {
            qw.ge("created_at", startDate + " 00:00:00");
        }
        if (endDate != null && !endDate.isEmpty()) {
            qw.le("created_at", endDate + " 23:59:59");
        }
        qw.orderByDesc("created_at");
        return adminOperationLogMapper.selectPage(new Page<>(page, size), qw);
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

        // 组装每日统计数据
        List<DailyStatsVO> stats = new ArrayList<>();
        LocalDate current = startDate;
        while (!current.isAfter(endDate)) {
            String dateStr = current.format(formatter);
            DailyStatsVO vo = new DailyStatsVO();
            vo.setDate(dateStr);
            vo.setNewUsers(userCountByDate.getOrDefault(dateStr, 0L));
            vo.setNewOrders(0L);
            vo.setRevenue(0);

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

        // 总订单数（已移除购买功能，设为0）
        overview.put("totalOrders", 0);

        // 总收入（已移除购买功能，设为0）
        overview.put("totalRevenue", 0);

        // 今日新增用户
        LocalDateTime todayStart = LocalDateTime.of(LocalDate.now(), LocalTime.MIN);
        LocalDateTime todayEnd = LocalDateTime.of(LocalDate.now(), LocalTime.MAX);
        LambdaQueryWrapper<User> todayUserWrapper = new LambdaQueryWrapper<>();
        todayUserWrapper.ge(User::getCreatedAt, todayStart)
                        .le(User::getCreatedAt, todayEnd);
        overview.put("todayNewUsers", userMapper.selectCount(todayUserWrapper));

        // 今日订单数（已移除购买功能，设为0）
        overview.put("todayOrders", 0);

        // 今日收入（已移除购买功能，设为0）
        overview.put("todayRevenue", 0);

        return overview;
    }

    @Override
    public Map<String, Object> getUserDetail(Long userId) {
        Map<String, Object> detail = new HashMap<>();

        // 获取用户基本信息
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.PARAM_ERROR, "用户不存在");
        }
        user.setPassword(null); // 清除密码
        detail.put("user", user);

        // 从 t_user_save_data 获取存档 JSON
        detail.put("saveData", loadSaveData(userId));

        return detail;
    }

    @Override
    public Map<String, Object> getUserDetailByUsername(String username) {
        Map<String, Object> detail = new HashMap<>();

        // 根据用户名查询用户
        LambdaQueryWrapper<User> userWrapper = new LambdaQueryWrapper<>();
        userWrapper.eq(User::getUsername, username);
        User user = userMapper.selectOne(userWrapper);
        if (user == null) {
            throw new BusinessException(ResultCode.PARAM_ERROR, "用户不存在");
        }
        user.setPassword(null); // 清除密码
        detail.put("user", user);

        // 从 t_user_save_data 获取存档 JSON
        detail.put("saveData", loadSaveData(user.getId()));

        return detail;
    }

    /**
     * 从 t_user_save_data 加载用户的存档 JSON，解析为 Map 返回。
     * 如果用户没有存档记录，返回默认值。
     */
    private Map<String, Object> loadSaveData(Long userId) {
        LambdaQueryWrapper<UserSaveData> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserSaveData::getUserId, userId);
        UserSaveData saveDataEntity = userSaveDataMapper.selectOne(wrapper);

        Map<String, Object> saveData = new LinkedHashMap<>();

        if (saveDataEntity != null && saveDataEntity.getSaveData() != null) {
            try {
                Map<String, Object> parsed = objectMapper.readValue(
                        saveDataEntity.getSaveData(),
                        new TypeReference<Map<String, Object>>() {});
                saveData.putAll(parsed);
            } catch (Exception e) {
                // JSON 解析失败，使用默认值
            }
        }

        // 确保所有字段都有默认值
        saveData.putIfAbsent("unlocked_characters", Arrays.asList("warrior"));
        saveData.putIfAbsent("character_levels", Collections.singletonMap("warrior", 1));
        saveData.putIfAbsent("unlocked_maps", Arrays.asList("map_1"));
        saveData.putIfAbsent("completed_maps", Collections.emptyList());
        saveData.putIfAbsent("unlocked_achievements", Collections.emptyList());
        saveData.putIfAbsent("coins", 0);
        saveData.putIfAbsent("diamonds", 0);

        // 附加地图定义信息（用于前端展示地图名称等）
        LambdaQueryWrapper<MapDefinition> mapDefWrapper = new LambdaQueryWrapper<>();
        mapDefWrapper.eq(MapDefinition::getIsActive, 1)
                     .orderByAsc(MapDefinition::getChapter)
                     .orderByAsc(MapDefinition::getOrderIndex);
        List<MapDefinition> allMaps = mapDefinitionMapper.selectList(mapDefWrapper);
        saveData.put("mapDefinitions", allMaps);

        // 附加角色定义信息（用于前端展示所有角色）
        LambdaQueryWrapper<CharacterDefinition> charDefWrapper = new LambdaQueryWrapper<>();
        charDefWrapper.eq(CharacterDefinition::getIsActive, 1)
                      .orderByAsc(CharacterDefinition::getId);
        List<CharacterDefinition> allChars = characterDefinitionMapper.selectList(charDefWrapper);
        saveData.put("characterDefinitions", allChars);

        return saveData;
    }

    @Override
    public void updateUser(Long userId, Map<String, Object> params) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.PARAM_ERROR, "用户不存在");
        }

        if (params.containsKey("nickname")) {
            user.setNickname((String) params.get("nickname"));
        }

        user.setUpdatedAt(LocalDateTime.now());
        userMapper.updateById(user);
    }

    @Override
    public void updateSaveData(Long userId, Map<String, Object> params) {
        // 查询或创建存档记录
        LambdaQueryWrapper<UserSaveData> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserSaveData::getUserId, userId);
        UserSaveData saveDataEntity = userSaveDataMapper.selectOne(wrapper);

        Map<String, Object> saveData = new LinkedHashMap<>();

        // 如果已有记录，先解析现有 JSON
        if (saveDataEntity != null && saveDataEntity.getSaveData() != null) {
            try {
                Map<String, Object> parsed = objectMapper.readValue(
                        saveDataEntity.getSaveData(),
                        new TypeReference<Map<String, Object>>() {});
                saveData.putAll(parsed);
            } catch (Exception e) {
                // JSON 解析失败，使用空 Map
            }
        }

        // 合并前端传来的字段
        if (params.containsKey("coins")) {
            saveData.put("coins", ((Number) params.get("coins")).intValue());
        }
        if (params.containsKey("diamonds")) {
            saveData.put("diamonds", ((Number) params.get("diamonds")).intValue());
        }
        if (params.containsKey("unlocked_characters")) {
            saveData.put("unlocked_characters", params.get("unlocked_characters"));
        }
        if (params.containsKey("character_levels")) {
            saveData.put("character_levels", params.get("character_levels"));
        }
        if (params.containsKey("unlocked_maps")) {
            saveData.put("unlocked_maps", params.get("unlocked_maps"));
        }
        if (params.containsKey("completed_maps")) {
            saveData.put("completed_maps", params.get("completed_maps"));
        }
        if (params.containsKey("unlocked_achievements")) {
            saveData.put("unlocked_achievements", params.get("unlocked_achievements"));
        }

        // 序列化为 JSON 字符串
        String json;
        try {
            json = objectMapper.writeValueAsString(saveData);
        } catch (Exception e) {
            throw new BusinessException(ResultCode.PARAM_ERROR, "存档数据序列化失败");
        }

        if (saveDataEntity != null) {
            // 更新已有记录
            saveDataEntity.setSaveData(json);
            saveDataEntity.setUpdatedAt(LocalDateTime.now());
            userSaveDataMapper.updateById(saveDataEntity);
        } else {
            // 创建新记录
            saveDataEntity = new UserSaveData();
            saveDataEntity.setUserId(userId);
            saveDataEntity.setSaveData(json);
            saveDataEntity.setCreatedAt(LocalDateTime.now());
            saveDataEntity.setUpdatedAt(LocalDateTime.now());
            userSaveDataMapper.insert(saveDataEntity);
        }
    }

    @Override
    public void deleteUserCompletely(Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.PARAM_ERROR, "用户不存在");
        }

        // 删除用户存档数据
        LambdaQueryWrapper<UserSaveData> saveDataWrapper = new LambdaQueryWrapper<>();
        saveDataWrapper.eq(UserSaveData::getUserId, userId);
        userSaveDataMapper.delete(saveDataWrapper);

        // 最后删除用户本身
        userMapper.deleteById(userId);
    }
}