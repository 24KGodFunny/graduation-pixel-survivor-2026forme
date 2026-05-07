<template>
  <div class="user-item-manage">
    <!-- 搜索栏 -->
    <div class="search-bar">
      <el-input
        v-model="searchForm.username"
        placeholder="搜索用户名"
        clearable
        class="search-input"
        @keyup.enter="handleSearch"
      >
        <template #prefix>
          <el-icon><Search /></el-icon>
        </template>
      </el-input>
      <el-input
        v-model="searchForm.itemName"
        placeholder="搜索物品名"
        clearable
        class="search-input"
        @keyup.enter="handleSearch"
      >
        <template #prefix>
          <el-icon><Search /></el-icon>
        </template>
      </el-input>
      <el-button type="primary" @click="handleSearch">
        <el-icon><Search /></el-icon> 搜索
      </el-button>
      <el-button @click="handleReset">
        <el-icon><Refresh /></el-icon> 重置
      </el-button>
    </div>

    <!-- 数据表格 -->
    <div class="table-card">
      <el-table :data="tableData" stripe v-loading="loading" class="pixel-table">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="username" label="用户名" width="130">
          <template #default="{ row }">
            <span class="user-name">{{ row.username }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="itemName" label="物品名称" width="160">
          <template #default="{ row }">
            <span class="item-name">🎒 {{ row.itemName }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="itemType" label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="getTypeTag(row.itemType)" size="small">
              {{ getTypeLabel(row.itemType) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="quantity" label="数量" width="80">
          <template #default="{ row }">
            <span class="quantity">×{{ row.quantity }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="price" label="单价" width="100">
          <template #default="{ row }">
            <span class="gold-text">🪙 {{ row.price }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="obtainedAt" label="获得时间" min-width="160" />
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.pageSize"
          :total="pagination.total"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next"
          @size-change="loadData"
          @current-change="loadData"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { Search, Refresh } from '@element-plus/icons-vue'
import { getUserItems } from '../api/admin'

const loading = ref(false)
const tableData = ref([])

const searchForm = reactive({
  username: '',
  itemName: ''
})

const pagination = reactive({
  page: 1,
  pageSize: 10,
  total: 0
})

onMounted(() => {
  loadData()
})

async function loadData() {
  loading.value = true
  try {
    const res = await getUserItems({
      page: pagination.page,
      pageSize: pagination.pageSize,
      username: searchForm.username || undefined,
      itemName: searchForm.itemName || undefined
    })
    if (res.code === 200) {
      tableData.value = res.data.records || []
      pagination.total = res.data.total || 0
    }
  } catch (e) {
    console.error('加载用户背包数据失败', e)
  } finally {
    loading.value = false
  }
}

function handleSearch() {
  pagination.page = 1
  loadData()
}

function handleReset() {
  searchForm.username = ''
  searchForm.itemName = ''
  pagination.page = 1
  loadData()
}

function getTypeTag(type) {
  const map = { WEAPON: 'danger', ARMOR: 'warning', CONSUMABLE: 'success', SKIN: 'info', PET: '' }
  return map[type] || 'info'
}

function getTypeLabel(type) {
  const map = { WEAPON: '武器', ARMOR: '护甲', CONSUMABLE: '消耗品', SKIN: '皮肤', PET: '宠物' }
  return map[type] || type
}
</script>

<style scoped>
.user-item-manage {
  padding: 0;
}

.search-bar {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
  padding: 20px;
  background: rgba(20, 16, 50, 0.6);
  border: 1px solid rgba(100, 80, 200, 0.15);
  border-radius: 12px;
}

.search-input {
  width: 220px;
}

.search-bar :deep(.el-input__wrapper) {
  background: rgba(15, 12, 40, 0.6);
  border: 1px solid rgba(100, 80, 200, 0.2);
  border-radius: 8px;
  box-shadow: none;
}

.search-bar :deep(.el-input__inner) {
  color: #d4d0e8;
}

.table-card {
  background: rgba(20, 16, 50, 0.6);
  border: 1px solid rgba(100, 80, 200, 0.15);
  border-radius: 12px;
  padding: 20px;
}

.user-name {
  color: #818cf8;
  font-weight: 500;
}

.item-name {
  color: #d4d0e8;
}

.quantity {
  color: #34d399;
  font-weight: 600;
  font-family: 'Courier New', monospace;
}

.gold-text {
  color: #f59e0b;
  font-weight: 600;
}

.pagination {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}

.pagination :deep(.el-pagination) {
  --el-pagination-bg-color: transparent;
  --el-pagination-text-color: #a098b8;
  --el-pagination-button-bg-color: rgba(30, 25, 60, 0.6);
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