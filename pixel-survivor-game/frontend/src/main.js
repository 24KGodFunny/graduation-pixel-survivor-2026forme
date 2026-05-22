import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'  // Element Plus 全局样式
import zhCn from 'element-plus/dist/locale/zh-cn.mjs'  // 中文语言包
import * as ElementPlusIconsVue from '@element-plus/icons-vue'  // 所有图标组件
import App from './App.vue'
import router from './router'

// 创建 Vue 应用实例
const app = createApp(App)

// 批量注册 Element Plus 图标组件
// 将 @element-plus/icons-vue 导出的所有图标注册为全局组件
// 这样在任何 .vue 文件中都可以直接使用图标名（如 <DataAnalysis />），无需导入
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

// 注册 Pinia（状态管理）
app.use(createPinia())
// 注册 Vue Router（路由管理）
app.use(router)
// 注册 Element Plus 组件库，locale: zhCn 使日期选择器等组件显示中文
app.use(ElementPlus, { locale: zhCn })

// 挂载到 index.html 中的 #app 根节点
app.mount('#app')