import { createRouter, createWebHistory } from 'vue-router'

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
  history: createWebHistory(),
  routes
})

// 路由守卫
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('admin_token')
  if (to.path !== '/login' && !token) {
    next('/login')
  } else {
    next()
  }
})

export default router