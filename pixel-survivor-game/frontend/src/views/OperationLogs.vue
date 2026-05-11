<template>
  <div>
    <!-- 筛选栏 -->
    <div class="filter-bar">
      <el-input v-model="filterForm.adminUsername" placeholder="管理员用户名" clearable style="width: 160px"
        @keyup.enter="handleSearch" />
      <el-select v-model="filterForm.module" placeholder="操作模块" clearable style="width: 150px">
        <el-option label="用户管理" value="用户管理" />
        <el-option label="用户数据管理" value="用户数据管理" />
        <el-option label="管理员管理" value="管理员管理" />
      </el-select>
      <el-date-picker v-model="filterForm.dateRange" type="daterange" range-separator="至" start-placeholder="开始日期"
        end-placeholder="结束日期" value-format="YYYY-MM-DD" style="width: 280px" />
      <el-button type="primary" @click="handleSearch">查询</el-button>
      <el-button @click="handleReset">重置</el-button>
    </div>

    <!-- 日志表格 -->
    <el-table :data="logs" border stripe class="pixel-table" v-loading="loading">
      <el-table-column prop="id" label="ID" width="60" align="center" />
      <el-table-column prop="adminUsername" label="操作管理员" width="120" align="center" />
      <el-table-column prop="module" label="操作模块" width="120" align="center">
        <template #default="{ row }">
          <el-tag :type="getModuleTagType(row.module)" size="small">{{ row.module }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="operation" label="操作类型" width="100" align="center" />
      <el-table-column prop="description" label="操作描述" min-width="180" show-overflow-tooltip />
      <el-table-column prop="ip" label="IP 地址" width="130" align="center" />
      <el-table-column prop="costTime" label="耗时(ms)" width="90" align="center">
        <template #default="{ row }">
          <span :style="{ color: row.costTime > 1000 ? '#f56c6c' : '#67c23a' }">{{ row.costTime }}</span>
        </template>
      </el-table-column>
      <el-table-column prop="status" label="状态" width="80" align="center">
        <template #default="{ row }">
          <el-tag :type="row.errorMsg ? 'danger' : 'success'" size="small">
            {{ row.errorMsg ? '失败' : '成功' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="createdAt" label="操作时间" width="170" align="center" />
    </el-table>

    <!-- 分页 -->
    <el-pagination style="margin-top: 15px" :current-page="page" :page-size="size" :total="total"
      @current-change="p => { page = p; loadData() }" layout="total, prev, pager, next" />
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { getLogs } from '../api/admin'

const logs = ref([])
const page = ref(1)
const size = 20
const total = ref(0)
const loading = ref(false)

const filterForm = reactive({
  adminUsername: '',
  module: '',
  dateRange: null
})

async function loadData() {
  loading.value = true
  try {
    const params = {
      page: page.value,
      size
    }
    if (filterForm.adminUsername) params.adminUsername = filterForm.adminUsername
    if (filterForm.module) params.module = filterForm.module
    if (filterForm.dateRange && filterForm.dateRange.length === 2) {
      params.startDate = filterForm.dateRange[0]
      params.endDate = filterForm.dateRange[1]
    }
    const res = await getLogs(params)
    logs.value = res.data.records
    total.value = res.data.total
  } finally {
    loading.value = false
  }
}

function handleSearch() {
  page.value = 1
  loadData()
}

function handleReset() {
  filterForm.adminUsername = ''
  filterForm.module = ''
  filterForm.dateRange = null
  page.value = 1
  loadData()
}

function getModuleTagType(module) {
  switch (module) {
    case '用户管理': return 'primary'
    case '用户数据管理': return 'warning'
    case '管理员管理': return 'success'
    default: return 'info'
  }
}

onMounted(loadData)
</script>

<style scoped>
.filter-bar {
  display: flex;
  gap: 10px;
  margin-bottom: 15px;
  align-items: center;
}

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