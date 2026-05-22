import axios from 'axios'
import { ElMessage } from 'element-plus'
import router from '../router'

/**
 * 创建 Axios 实例
 *
 * 配置说明：
 * - baseURL: '/api/admin' —— 所有请求自动添加此前缀，由 Vite 代理转发到真实后端
 * - timeout: 10000ms —— 超时时间 10 秒
 */
const request = axios.create({
  baseURL: '/api/admin',
  timeout: 10000
})

/**
 * 请求拦截器
 *
 * 职责：在每个请求发出前，自动从 localStorage 读取 token 并附加到请求头
 * 认证方式：Bearer Token（JWT 标准格式）
 * 这样所有通过此 request 实例发出的请求都自动携带认证信息，无需在每个 API 函数中手动添加
 */
request.interceptors.request.use(config => {
  const token = localStorage.getItem('admin_token')
  if (token) {
    // 添加 Bearer 前缀，符合 OAuth 2.0 规范
    config.headers['Authorization'] = `Bearer ${token}`
  }
  return config
})

/**
 * 响应拦截器
 *
 * 职责：统一处理所有 HTTP 响应
 *
 * 成功回调（response =>）：
 * 1. 检查业务状态码 res.code
 * 2. code === 200：直接返回 res，业务代码可直接使用
 * 3. code !== 200：弹出错误提示，若为 401 则清除 token 并跳转登录页
 *    注意：这里 return Promise.reject() 以便上层 catch 捕获
 *
 * 失败回调（error =>）：
 * 1. 网络错误或 HTTP 错误（如 500、超时等）
 * 2. 弹出通用网络错误提示
 * 3. return Promise.reject(error) 继续向上抛出
 */
request.interceptors.response.use(
  response => {
    const res = response.data
    if (res.code !== 200) {
      // 业务错误：显示后端返回的错误信息
      ElMessage.error(res.message || '请求失败')
      // 401 未授权：token 过期或无效 -> 清除登录态 -> 跳转登录页
      if (res.code === 401) {
        localStorage.removeItem('admin_token')
        router.push('/login')
      }
      // 返回 reject 让调用方可以通过 try/catch 处理
      return Promise.reject(new Error(res.message))
    }
    return res
  },
  error => {
    // 网络层面的错误（无响应、超时等）
    ElMessage.error(error.message || '网络错误')
    return Promise.reject(error)
  }
)

export default request