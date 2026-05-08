import request from '../utils/request'

// ==================== 认证 ====================
export function login(data) {
  return request.post('/login', data)
}

export function registerAdmin(data) {
  return request.post('/register', data)
}

export function changePassword(data) {
  return request.put('/password', data)
}

// ==================== 仪表盘 ====================
export function getDashboardStats() {
  return request.get('/dashboard/overview')
}

export function getDailyStats(range) {
  return request.get('/dashboard/daily-stats', { params: { range } })
}

// ==================== 用户管理 ====================
export function getUsers(params) {
  return request.get('/users', { params })
}

export function banUser(id) {
  return request.put(`/users/${id}/ban`)
}

export function unbanUser(id) {
  return request.put(`/users/${id}/unban`)
}

// ==================== 管理员管理 ====================
export function getAdmins(params) {
  return request.get('/admins', { params })
}

export function deleteAdmin(id) {
  return request.delete(`/admins/${id}`)
}

// ==================== 操作日志 ====================
export function getLogs(params) {
  return request.get('/logs', { params })
}

// ==================== 用户数据管理 ====================
export function deleteUser(userId) {
  return request.delete(`/users/${userId}`)
}

export function getUserDetail(userId) {
  return request.get(`/users/${userId}/detail`)
}

export function getUserDetailByUsername(username) {
  return request.get('/users/detail-by-username', { params: { username } })
}

export function updateUser(userId, data) {
  return request.put(`/users/${userId}`, data)
}

export function updateSaveData(userId, data) {
  return request.put(`/users/${userId}/save-data`, data)
}
