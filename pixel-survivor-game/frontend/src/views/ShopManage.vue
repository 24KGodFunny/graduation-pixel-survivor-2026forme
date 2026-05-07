<template>
  <div>
    <div style="margin-bottom: 15px; display: flex; justify-content: space-between">
      <div>
        <el-select v-model="typeFilter" placeholder="筛选类型" clearable style="width: 150px; margin-right: 10px" @change="loadData">
          <el-option label="皮肤" :value="1" />
          <el-option label="武器" :value="2" />
          <el-option label="消耗品" :value="3" />
          <el-option label="礼包" :value="4" />
          <el-option label="通行证" :value="5" />
        </el-select>
      </div>
      <el-button type="primary" @click="showDialog()">新增商品</el-button>
    </div>

    <el-table :data="items" border stripe class="pixel-table">
      <el-table-column prop="id" label="ID" width="60" />
      <el-table-column prop="name" label="名称" />
      <el-table-column prop="itemType" label="类型" width="80">
        <template #default="{ row }">
          {{ itemTypeMap[row.itemType] || '未知' }}
        </template>
      </el-table-column>
      <el-table-column prop="priceCoin" label="游戏币" width="80" />
      <el-table-column prop="priceDiamond" label="钻石" width="80" />
      <el-table-column prop="rarity" label="稀有度" width="80">
        <template #default="{ row }">
          <el-tag :type="rarityTagType[row.rarity]">{{ rarityMap[row.rarity] || '未知' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="stock" label="库存" width="70">
        <template #default="{ row }">
          {{ row.stock === -1 ? '无限' : row.stock }}
        </template>
      </el-table-column>
      <el-table-column prop="status" label="状态" width="80">
        <template #default="{ row }">
          <el-tag :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? '上架' : '下架' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="160">
        <template #default="{ row }">
          <el-button size="small" @click="showDialog(row)">编辑</el-button>
          <el-popconfirm title="确定删除?" @confirm="handleDelete(row.id)">
            <template #reference>
              <el-button size="small" type="danger">删除</el-button>
            </template>
          </el-popconfirm>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination style="margin-top: 15px" :current-page="page" :page-size="size" :total="total"
      @current-change="p => { page = p; loadData() }" layout="total, prev, pager, next" />

    <el-dialog v-model="dialogVisible" :title="editId ? '编辑商品' : '新增商品'" width="600px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="名称"><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="类型">
          <el-select v-model="form.itemType">
            <el-option label="皮肤" :value="1" />
            <el-option label="武器" :value="2" />
            <el-option label="消耗品" :value="3" />
            <el-option label="礼包" :value="4" />
            <el-option label="通行证" :value="5" />
          </el-select>
        </el-form-item>
        <el-form-item label="游戏币价格"><el-input-number v-model="form.priceCoin" :min="0" /></el-form-item>
        <el-form-item label="钻石价格"><el-input-number v-model="form.priceDiamond" :min="0" /></el-form-item>
        <el-form-item label="稀有度">
          <el-select v-model="form.rarity">
            <el-option label="普通" :value="1" />
            <el-option label="稀有" :value="2" />
            <el-option label="史诗" :value="3" />
            <el-option label="传说" :value="4" />
          </el-select>
        </el-form-item>
        <el-form-item label="描述"><el-input v-model="form.description" type="textarea" /></el-form-item>
        <el-form-item label="图片URL"><el-input v-model="form.imageUrl" /></el-form-item>
        <el-form-item label="库存"><el-input-number v-model="form.stock" :min="-1" /> <span style="margin-left: 10px; color: #999">-1为无限</span></el-form-item>
        <el-form-item label="限购"><el-input-number v-model="form.maxBuyCount" :min="-1" /> <span style="margin-left: 10px; color: #999">-1为无限</span></el-form-item>
        <el-form-item label="效果类型"><el-input v-model="form.effectType" /></el-form-item>
        <el-form-item label="效果数值"><el-input-number v-model="form.effectValue" :min="0" /></el-form-item>
        <el-form-item label="效果持续(秒)"><el-input-number v-model="form.effectDuration" :min="0" /></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="form.sortOrder" :min="0" /></el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="上架" inactive-text="下架" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { getShopItems, addItem, updateItem, deleteItem } from '../api/admin'

const itemTypeMap = { 1: '皮肤', 2: '武器', 3: '消耗品', 4: '礼包', 5: '通行证' }
const rarityMap = { 1: '普通', 2: '稀有', 3: '史诗', 4: '传说' }
const rarityTagType = { 1: 'info', 2: 'success', 3: '', 4: 'warning' }

const items = ref([])
const page = ref(1)
const size = 20
const total = ref(0)
const typeFilter = ref('')
const dialogVisible = ref(false)
const editId = ref(null)
const defaultForm = {
  name: '', itemType: 1, priceCoin: 0, priceDiamond: 0,
  description: '', imageUrl: '', rarity: 1, stock: -1,
  maxBuyCount: -1, effectType: '', effectValue: 0,
  effectDuration: 0, sortOrder: 0, status: 1
}
const form = reactive({ ...defaultForm })

async function loadData() {
  const res = await getShopItems({ page: page.value, size, type: typeFilter.value || undefined })
  items.value = res.data.records
  total.value = res.data.total
}

function showDialog(row) {
  if (row) {
    editId.value = row.id
    Object.assign(form, row)
  } else {
    editId.value = null
    Object.assign(form, { ...defaultForm })
  }
  dialogVisible.value = true
}

async function handleSubmit() {
  if (editId.value) {
    await updateItem(editId.value, form)
    ElMessage.success('更新成功')
  } else {
    await addItem(form)
    ElMessage.success('添加成功')
  }
  dialogVisible.value = false
  loadData()
}

async function handleDelete(id) {
  await deleteItem(id)
  ElMessage.success('删除成功')
  loadData()
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
