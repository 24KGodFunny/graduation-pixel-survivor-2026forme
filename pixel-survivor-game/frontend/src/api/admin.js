import request from '../utils/request'

/**
 * API 接口层
 *
 * 所有接口函数都使用上面封装的 request 实例（axios.create({ baseURL: '/api/admin' })）
 * 因此实际请求路径为：'/api/admin' + 函数中的路径
 *
 * 按业务模块分组：
 * - 认证（登录、注册、改密）
 * - 仪表盘（概览统计、每日趋势）
 * - 用户管理（列表、封禁/解封）
 * - 管理员管理（列表、删除）
 * - 操作日志（列表）
 * - 用户数据管理（详情、更新基本信息、更新存档、删除用户）
 */

// ==================== 认证 ====================
/** 管理员登录 */
export function login(data) {
  return request.post('/login', data)
}

/** 注册新管理员 */
export function registerAdmin(data) {
  return request.post('/register', data)
}

/** 修改当前管理员密码 */
export function changePassword(data) {
  return request.put('/password', data)
}

// ==================== 仪表盘 ====================
/** 获取仪表盘概览统计（总用户数、今日新增等） */
export function getDashboardStats() {
  return request.get('/dashboard/overview')
}

/** 获取每日趋势数据（用于 ECharts 图表），range 可为 '7d' | '30d' | '3m' */
export function getDailyStats(range) {
  return request.get('/dashboard/daily-stats', { params: { range } })
}

// ==================== 用户管理 ====================
/** 获取用户列表（支持分页和关键词搜索） */
export function getUsers(params) {
  return request.get('/users', { params })
}

/** 封禁用户（根据用户 ID） */
export function banUser(id) {
  return request.put(`/users/${id}/ban`)
}

/** 解封用户（根据用户 ID） */
export function unbanUser(id) {
  return request.put(`/users/${id}/unban`)
}

// ==================== 管理员管理 ====================
/** 获取管理员列表（分页） */
export function getAdmins(params) {
  return request.get('/admins', { params })
}

/** 删除管理员（根据 ID） */
export function deleteAdmin(id) {
  return request.delete(`/admins/${id}`)
}

// ==================== 操作日志 ====================
/**
 * 获取操作日志列表
 * 支持筛选参数：adminUsername、module、startDate、endDate、page、size
 */
export function getLogs(params) {
  return request.get('/logs', { params })
}

// ==================== 用户数据管理 ====================
/**
 * 删除用户（根据用户 ID）
 * 注意：此操作会级联删除该用户的背包、地图进度、游戏统计等所有关联数据
 */
export function deleteUser(userId) {
  return request.delete(`/users/${userId}`)
}

/** 获取用户详细信息（通过用户 ID） */
export function getUserDetail(userId) {
  return request.get(`/users/${userId}/detail`)
}

/**
 * 通过用户名查询用户详细信息
 * 与 getUserDetail 的区别：不需要知道用户 ID，直接用用户名搜索
 */
export function getUserDetailByUsername(username) {
  return request.get('/users/detail-by-username', { params: { username } })
}

/** 更新用户基本信息（如昵称） */
export function updateUser(userId, data) {
  return request.put(`/users/${userId}`, data)
}

/**
 * 更新用户存档数据
 * 包括：金币、钻石、已解锁角色、角色等级、已解锁地图、已通关地图
 */
export function updateSaveData(userId, data) {
  return request.put(`/users/${userId}/save-data`, data)
}