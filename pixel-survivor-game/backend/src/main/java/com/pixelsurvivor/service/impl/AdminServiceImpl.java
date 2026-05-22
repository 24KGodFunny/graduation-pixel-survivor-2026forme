package com.pixelsurvivor.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pixelsurvivor.common.constant.RedisConstant;
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
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

/**
 * 管理员服务实现类
 * <p>实现管理员登录认证、操作日志分页查询等业务逻辑，
 * 使用 BCrypt 进行密码校验</p>
 *
 * @author PixelSurvivor
 */
@Slf4j
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
    private final RedisTemplate<String, Object> redisTemplate;
    private final StringRedisTemplate stringRedisTemplate;

    /**
     * 管理员登录
     * <p>根据用户名查询管理员记录，使用 BCrypt 验证密码是否匹配。</p>
     *
     * @param username 管理员用户名
     * @param password 明文密码（将与数据库中的 BCrypt 密文比对）
     * @return 登录成功的管理员实体
     * @throws BusinessException 用户名或密码错误时抛出 USERNAME_OR_PASSWORD_ERROR 异常
     */
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

    /**
     * 管理员注册
     * <p>校验用户名是否已存在，使用 BCrypt 加密密码后保存管理员信息。
     * 返回结果前会清除密码字段，避免敏感信息泄露到前端。</p>
     *
     * @param username 管理员用户名（不可重复）
     * @param password 明文密码（将被 BCrypt 加密后存储）
     * @param role     管理员角色（如 SUPER_ADMIN、ADMIN 等）
     * @return 注册成功的管理员实体（密码字段已置空）
     * @throws BusinessException 当用户名已存在时抛出 USERNAME_EXISTS 异常
     */
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

    /**
     * 分页获取管理员列表
     * <p>按创建时间倒序排列。返回前遍历所有记录清除密码字段，
     * 防止密码密文泄露到前端。</p>
     *
     * @param page 当前页码（从 1 开始）
     * @param size 每页记录数
     * @return 分页后的管理员数据（密码字段已被清除）
     */
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

    /**
     * 删除管理员
     * <p>安全限制：不允许管理员删除自己（防止误操作将自己锁在系统外），
     * 不允许删除超级管理员（SUPER_ADMIN 角色，保护系统最高权限账户）。</p>
     *
     * @param id             待删除的管理员 ID
     * @param currentAdminId 当前登录管理员 ID（用于防止自我删除）
     * @throws BusinessException 当尝试删除自己时抛出 PARAM_ERROR 异常（提示"不能删除自己"）
     * @throws BusinessException 当管理员不存在时抛出 PARAM_ERROR 异常（提示"管理员不存在"）
     * @throws BusinessException 当尝试删除超级管理员时抛出 PARAM_ERROR 异常（提示"不能删除超级管理员"）
     */
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

    /**
     * 分页查询管理员操作日志
     * <p>支持按管理员用户名（模糊匹配）、操作模块（精确匹配）、
     * 日期范围（起止日期）等多条件组合筛选。
     * 日期筛选使用 >= startDate 00:00:00 且 <= endDate 23:59:59 的闭区间策略。
     * 结果按创建时间倒序排列。</p>
     *
     * @param page          当前页码（从 1 开始）
     * @param size          每页记录数
     * @param adminUsername 管理员用户名（可选，模糊匹配 LIKE）
     * @param module        操作模块名称（可选，精确匹配）
     * @param startDate     起始日期（可选，格式 yyyy-MM-dd，闭区间包含当日 00:00:00）
     * @param endDate       截止日期（可选，格式 yyyy-MM-dd，闭区间包含当日 23:59:59）
     * @return 分页后的操作日志记录
     */
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

    /**
     * 管理员修改密码
     * <p>先校验旧密码是否正确（通过 BCrypt 比对），验证通过后使用 BCrypt 加密新密码并保存。</p>
     *
     * @param adminId     管理员 ID
     * @param oldPassword 旧密码（用于身份验证，明文）
     * @param newPassword 新密码（将被 BCrypt 加密后存储）
     * @throws BusinessException 当管理员不存在时抛出 PARAM_ERROR 异常（提示"管理员不存在"）
     * @throws BusinessException 当旧密码错误时抛出 PARAM_ERROR 异常（提示"原密码错误"）
     */
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

    /**
     * 获取每日统计数据（用于管理端折线图/柱状图展示）
     * <p>根据时间范围参数计算起始日期，查询该时间段内每天的新增注册用户数，
     * 按日期升序生成统计数据列表。
     * 注意：newOrders（新增订单）和 revenue（收入）字段硬编码返回 0，
     * 因为项目目前不包含购买/支付功能，保留这两个字段仅为前端图表结构兼容。</p>
     *
     * @param range 时间范围，支持 "7d"（近7天）、"30d"（近30天）、"3m"（近3个月）、"6m"（近6个月），
     *              默认按 "7d" 处理
     * @return 每日统计数据列表，按日期升序排列，包含 newUsers、newOrders(=0)、revenue(=0)
     */
    @Override
    public List<DailyStatsVO> getDailyStats(String range) {
        String cacheKey = RedisConstant.DASHBOARD_DAILY + range;

        // 1. 先查 Redis 缓存
        try {
            @SuppressWarnings("unchecked")
            List<DailyStatsVO> cached = (List<DailyStatsVO>) redisTemplate.opsForValue().get(cacheKey);
            if (cached != null) {
                return cached;
            }
        } catch (Exception e) {
            log.warn("Redis查询每日统计缓存失败，降级查询数据库: {}", e.getMessage());
        }

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

        // 2. 写入 Redis 缓存（TTL 10 分钟）
        try {
            redisTemplate.opsForValue().set(cacheKey, stats, 10, TimeUnit.MINUTES);
        } catch (Exception e) {
            log.warn("Redis写入每日统计缓存失败: {}", e.getMessage());
        }

        return stats;
    }

    /**
     * 获取管理端仪表盘概览数据
     * <p>统计关键运营指标：总用户数、今日新增用户数。
     * 注意：totalOrders、totalRevenue、todayOrders、todayRevenue 字段固定返回 0，
     * 因为项目目前不包含购买/支付功能，保留这些字段仅为前端仪表盘结构兼容。</p>
     *
     * @return 包含 totalUsers（总用户数）、totalOrders(=0)、totalRevenue(=0)、
     *         todayNewUsers（今日新增）、todayOrders(=0)、todayRevenue(=0) 的 Map
     */
    @Override
    public Map<String, Object> getDashboardOverview() {
        String cacheKey = RedisConstant.DASHBOARD_OVERVIEW;

        // 1. 先查 Redis 缓存
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> cached = (Map<String, Object>) redisTemplate.opsForValue().get(cacheKey);
            if (cached != null) {
                return cached;
            }
        } catch (Exception e) {
            log.warn("Redis查询仪表盘概览缓存失败，降级查询数据库: {}", e.getMessage());
        }

        Map<String, Object> overview = new HashMap<>();

        // 2. 总用户数
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

        // 3. 在线用户数（从 Redis Set 获取）
        try {
            Long onlineCount = stringRedisTemplate.opsForSet().size(RedisConstant.USER_ONLINE);
            overview.put("onlineUsers", onlineCount != null ? onlineCount : 0L);
        } catch (Exception e) {
            log.warn("Redis查询在线用户数失败: {}", e.getMessage());
            overview.put("onlineUsers", 0L);
        }

        // 4. 写入 Redis 缓存（TTL 5 分钟）
        try {
            redisTemplate.opsForValue().set(cacheKey, overview, 5, TimeUnit.MINUTES);
        } catch (Exception e) {
            log.warn("Redis写入仪表盘概览缓存失败: {}", e.getMessage());
        }

        return overview;
    }

    /**
     * 获取用户详情（按用户 ID 查询）
     * <p>查询用户的基本信息（密码字段已清除，防止泄露）和游戏存档数据。
     * 存档数据包含已解锁角色、角色等级、已解锁地图、已完成地图、
     * 成就列表、游戏币和钻石等字段，并额外附带地图定义列表（mapDefinitions）
     * 和角色定义列表（characterDefinitions），供管理端前端渲染存档编辑界面时使用。</p>
     *
     * @param userId 用户 ID
     * @return 包含 user（用户实体，无密码）和 saveData（存档各字段的 Map）的详情数据
     * @throws BusinessException 当用户不存在时抛出 PARAM_ERROR 异常（提示"用户不存在"）
     */
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

    /**
     * 获取用户详情（按用户名查询）
     * <p>功能与 {@link #getUserDetail(Long)} 完全一致，区别在于通过用户名定位用户。
     * 方便管理端通过用户名快速查找玩家信息。</p>
     *
     * @param username 用户名
     * @return 包含 user（用户实体，无密码）和 saveData（存档各字段的 Map）的详情数据
     * @throws BusinessException 当用户不存在时抛出 PARAM_ERROR 异常（提示"用户不存在"）
     */
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
     * 从 t_user_save_data 表加载用户的存档 JSON 数据，解析为 Map 返回
     * <p>如果用户没有存档记录或 JSON 解析失败，则返回预设的默认值：
     * 默认解锁战士（warrior）角色和 map_1 地图，其余字段均为空。
     * 返回的 Map 中额外附加 mapDefinitions（活跃地图定义列表，按章节和排序序号排列）
     * 和 characterDefinitions（活跃角色定义列表，按 ID 升序），
     * 供管理端前端渲染存档编辑界面时展示下拉选项等配置信息。</p>
     *
     * @param userId 用户 ID
     * @return 包含所有存档字段默认值的 Map，并附带地图和角色定义信息
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

    /**
     * 更新用户基本信息（管理端操作）
     * <p>当前仅支持更新用户昵称（nickname）字段。从 params Map 中按 key 取出对应字段值进行更新。
     * 可根据后续需求扩展更多可编辑字段（如账号状态等）。</p>
     *
     * @param userId 用户 ID
     * @param params 待更新的字段键值对（当前支持：nickname）
     * @throws BusinessException 当用户不存在时抛出 PARAM_ERROR 异常（提示"用户不存在"）
     */
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

    /**
     * 更新用户游戏存档数据（管理端编辑）
     * <p>先查询用户已有的存档 JSON 并解析为 Map（保留未修改的字段），
     * 再用 params 中的新值覆盖对应字段，实现增量合并更新。
     * 合并后的存档数据序列化为 JSON 字符串后通过 upsert 写入 t_user_save_data 表。
     * 支持的存档字段：coins（游戏币）、diamonds（钻石）、unlocked_characters（已解锁角色）、
     * character_levels（角色等级 Map）、unlocked_maps（已解锁地图）、
     * completed_maps（已完成地图）、unlocked_achievements（已解锁成就）。</p>
     *
     * @param userId 用户 ID
     * @param params 待更新的存档字段键值对（按需传入，未传入的字段保留原值）
     * @throws BusinessException 当 JSON 序列化失败时抛出 PARAM_ERROR 异常（提示"存档数据序列化失败"）
     */
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

    /**
     * 彻底删除用户（管理端操作）
     * <p>采用先删关联数据再删主数据的顺序：
     * 第一步删除 t_user_save_data 表中该用户的存档记录（通过 userId 匹配）；
     * 第二步删除 t_user 表中该用户的账号记录。
     * 这种顺序可以避免因外键约束或孤儿数据导致的问题。</p>
     *
     * @param userId 用户 ID
     * @throws BusinessException 当用户不存在时抛出 PARAM_ERROR 异常（提示"用户不存在"）
     */
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