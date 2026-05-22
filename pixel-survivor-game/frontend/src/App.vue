<template>
  <!-- 根组件：仅作为路由出口，所有页面由 vue-router 按路由配置渲染 -->
  <router-view />
</template>

<script setup>
// 根组件无额外逻辑，仅为整个应用提供根 DOM 节点
// 全局样式（reset + 字体）在下面 <style> 块中定义，未使用 scoped 以作用于全局
</script>

<style>
/* 全局样式重置：清除浏览器默认边距、padding、盒模型 */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

/* 全局字体设置 */
body {
  font-family: 'Microsoft YaHei', sans-serif;
}
</style>