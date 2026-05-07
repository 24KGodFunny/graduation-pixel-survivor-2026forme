<template>
  <div>
    <el-table :data="logs" border stripe class="pixel-table">
      <el-table-column prop="id" label="ID" width="60" />
      <el-table-column prop="adminUsername" label="管理员" width="100" />
      <el-table-column prop="operation" label="操作" />
      <el-table-column prop="method" label="方法" />
      <el-table-column prop="params" label="参数" show-overflow-tooltip />
      <el-table-column prop="ip" label="IP" width="130" />
      <el-table-column prop="createTime" label="时间" width="170" />
    </el-table>

    <el-pagination style="margin-top: 15px" :current-page="page" :page-size="size" :total="total"
      @current-change="p => { page = p; loadData() }" layout="total, prev, pager, next" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getLogs } from '../api/admin'

const logs = ref([])
const page = ref(1)
const size = 20
const total = ref(0)

async function loadData() {
  const res = await getLogs({ page: page.value, size })
  logs.value = res.data.records
  total.value = res.data.total
}

onMounted(loadData)
</script>

<style scoped>
.pixel-table :deep(.el-table__header th) {
  background: rgba(30, 25, 60, 0.8) !important;
  color: #ffffff;
}

.pixel-table :deep(.el-table__row) {
  background: rgba(40, 35, 70, 0.5) !important;
  color: #ffffff;
}

.pixel-table :deep(.el-table__row td) {
  color: #ffffff;
  border-bottom-color: rgba(100, 80, 200, 0.1);
}

.pixel-table :deep(.el-table__row--striped td) {
  background: rgba(50, 45, 80, 0.5) !important;
  color: #ffffff;
}

.pixel-table :deep(.el-table__row:hover > td) {
  background: rgba(100, 80, 200, 0.15) !important;
}

.pixel-table {
  --el-table-bg-color: transparent;
  --el-table-tr-bg-color: transparent;
  --el-table-header-bg-color: transparent;
  --el-table-row-hover-bg-color: transparent;
  --el-table-border-color: rgba(100, 80, 200, 0.1);
  --el-table-text-color: #ffffff;
  --el-table-header-text-color: #ffffff;
}
</style>
