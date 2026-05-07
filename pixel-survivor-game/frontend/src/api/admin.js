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

// ==================== 商品管理 ====================
export function getShopItems(params) {
  return request.get('/shop/items', { params })
}

export function addItem(data) {
  return request.post('/shop/items', data)
}

export function updateItem(id, data) {
  return request.put(`/shop/items/${id}`, data)
}

export function deleteItem(id) {
  return request.delete(`/shop/items/${id}`)
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

// ==================== 用户背包管理 ====================
export function getUserItems(params) {
  return request.get('/user-items', { params })
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