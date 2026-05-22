import { defineStore } from 'pinia'
import { ref } from 'vue'

/**
 * 管理员状态管理 Store (Pinia)
 *
 * 职责：
 * 1. 管理管理员登录状态（token、username、role）
 * 2. 与 localStorage 双向同步，确保刷新页面后仍然保持登录状态
 * 3. 提供 setLoginInfo 和 logout 两个操作方法
 *
 * 使用 Composition API 风格（推荐）：defineStore 第二个参数为 setup 函数
 * 数据流向：登录 -> setLoginInfo（写入 ref + localStorage）-> 页面刷新 -> 从 localStorage 读取初始值
 */
export const useAdminStore = defineStore('admin', () => {
  // 初始化时从 localStorage 读取持久化的登录信息
  // 如果 localStorage 中无数据，默认空字符串（表示未登录）
  const token = ref(localStorage.getItem('admin_token') || '')
  const username = ref(localStorage.getItem('admin_username') || '')
  const role = ref(localStorage.getItem('admin_role') || '')

  /**
   * 设置登录信息
   * 登录成功后调用：将后端返回的 token/username/role 同时写入 Pinia 状态和 localStorage
   *
   * @param {Object} data - 后端返回的登录数据 { token, username, role }
   */
  function setLoginInfo(data) {
    token.value = data.token
    username.value = data.username
    role.value = data.role
    // 同步写入 localStorage，实现持久化（页面刷新后仍保持登录态）
    localStorage.setItem('admin_token', data.token)
    localStorage.setItem('admin_username', data.username)
    localStorage.setItem('admin_role', data.role)
  }

  /**
   * 退出登录
   * 清空所有状态并移除 localStorage 中的数据
   * 注意：不需要调用后端接口，只是前端清除认证信息
   */
  function logout() {
    token.value = ''
    username.value = ''
    role.value = ''
    localStorage.removeItem('admin_token')
    localStorage.removeItem('admin_username')
    localStorage.removeItem('admin_role')
  }

  // 暴露响应式状态和方法给组件使用
  return { token, username, role, setLoginInfo, logout }
})