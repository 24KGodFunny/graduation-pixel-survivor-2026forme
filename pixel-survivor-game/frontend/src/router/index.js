import { createRouter, createWebHistory } from 'vue-router'

/**
 * 路由配置
 *
 * 架构设计：
 * - /login：独立路由，不嵌套在 AdminLayout 中（登录页不需要侧边栏和顶栏）
 * - /：AdminLayout 作为父路由壳，所有管理页面作为其子路由
 *   - 子路由通过 router-view 渲染在 AdminLayout 的 <el-main> 区域
 *   - redirect 将根路径自动重定向到仪表盘
 * - 所有页面组件使用动态 import（懒加载），按需分割打包
 * - meta.title 用于 AdminLayout 顶栏动态显示页面标题
 */
const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue')
  },
  {
    path: '/',
    component: () => import('../layout/AdminLayout.vue'),
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('../views/Dashboard.vue'),
        meta: { title: '数据概览' }
      },
      {
        path: 'users',
        name: 'UserManage',
        component: () => import('../views/UserManage.vue'),
        meta: { title: '用户管理' }
      },
      {
        path: 'map-stats',
        name: 'MapStats',
        component: () => import('../views/MapStats.vue'),
        meta: { title: '地图统计' }
      },
      {
        path: 'user-data',
        name: 'UserDataManage',
        component: () => import('../views/UserDataManage.vue'),
        meta: { title: '用户数据管理' }
      },
      {
        path: 'logs',
        name: 'OperationLogs',
        component: () => import('../views/OperationLogs.vue'),
        meta: { title: '操作日志' }
      },
      {
        path: 'admins',
        name: 'AdminManage',
        component: () => import('../views/AdminManage.vue'),
        meta: { title: '管理员管理' }
      },
      {
        path: 'profile',
        name: 'Profile',
        component: () => import('../views/Profile.vue'),
        meta: { title: '我的' }
      }
    ]
  }
]

const router = createRouter({
  // createWebHistory 使用 HTML5 History API，需要服务器配置 fallback
  history: createWebHistory(),
  routes
})

/**
 * 全局前置路由守卫
 *
 * 认证逻辑：
 * - 检查 localStorage 中是否存在 admin_token
 * - 如果目标不是 /login 且没有 token，强制跳转到登录页
 * - 如果有 token 或目标就是 /login，正常放行
 *
 * 注意：这里只是前端层面的简单鉴权，真正的权限校验在后端通过 JWT token 完成
 */
function isTokenExpired(token) {
  try {
    const base64Url = token.split('.')[1]
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/')
    const payload = JSON.parse(atob(base64))
    return payload.exp * 1000 < Date.now()
  } catch {
    return true
  }
}

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('admin_token')
  if (to.path !== '/login') {
    if (!token || isTokenExpired(token)) {
      localStorage.removeItem('admin_token')
      localStorage.removeItem('admin_username')
      localStorage.removeItem('admin_role')
      next('/login')
      return
    }
  }
  next()
})

export default router