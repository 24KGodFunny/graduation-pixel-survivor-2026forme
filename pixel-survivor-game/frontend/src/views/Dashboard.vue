<template>
  <div class="dashboard">
    <!-- 统计卡片 -->
    <el-row :gutter="20" class="stat-cards">
      <el-col :span="6">
        <div class="stat-card card-users">
          <div class="stat-icon">👥</div>
          <div class="stat-info">
            <div class="stat-value">{{ stats.totalUsers || 0 }}</div>
            <div class="stat-label">总用户数</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card card-orders">
          <div class="stat-icon">🛒</div>
          <div class="stat-info">
            <div class="stat-value">{{ stats.totalOrders || 0 }}</div>
            <div class="stat-label">总订单数</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card card-today">
          <div class="stat-icon">📅</div>
          <div class="stat-info">
            <div class="stat-value">{{ stats.todayNewUsers || 0 }}</div>
            <div class="stat-label">今日新增用户</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card card-revenue">
          <div class="stat-icon">💰</div>
          <div class="stat-info">
            <div class="stat-value">{{ stats.totalRevenue || 0 }}</div>
            <div class="stat-label">总收入(金币)</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 图表区域 -->
    <el-row :gutter="20" class="chart-row">
      <el-col :span="16">
        <div class="chart-card">
          <div class="chart-header">
            <h3>📈 每日数据趋势</h3>
            <el-radio-group v-model="chartDays" size="small" @change="loadDailyStats">
              <el-radio-button value="7d">近7天</el-radio-button>
              <el-radio-button value="30d">近30天</el-radio-button>
              <el-radio-button value="3m">近3月</el-radio-button>
            </el-radio-group>
          </div>
          <div ref="trendChartRef" class="chart-container"></div>
        </div>
      </el-col>
      <el-col :span="8">
        <div class="chart-card">
          <div class="chart-header">
            <h3>🎮 游戏类型分布</h3>
          </div>
          <div ref="pieChartRef" class="chart-container"></div>
        </div>
      </el-col>
    </el-row>

    <!-- 最近订单 -->
    <div class="chart-card recent-section">
      <div class="chart-header">
        <h3>🕐 最近购买记录</h3>
      </div>
      <el-table :data="recentPurchases" stripe class="pixel-table">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="username" label="用户" width="120" />
        <el-table-column prop="itemName" label="商品" width="150" />
        <el-table-column prop="price" label="价格" width="100">
          <template #default="{ row }">
            <span class="gold-text">🪙 {{ row.price }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="quantity" label="数量" width="80" />
        <el-table-column prop="totalPrice" label="总价" width="100">
          <template #default="{ row }">
            <span class="gold-text">🪙 {{ row.totalPrice }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="createdAt" label="购买时间" />
      </el-table>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import { getDashboardStats, getDailyStats } from '../api/admin'

const stats = reactive({
  totalUsers: 0,
  totalOrders: 0,
  totalRevenue: 0,
  todayNewUsers: 0,
  todayOrders: 0,
  todayRevenue: 0
})

const recentPurchases = ref([]) // 后端暂未返回，保留为空数组
const chartDays = ref('7d')
const trendChartRef = ref(null)
const pieChartRef = ref(null)

let trendChart = null
let pieChart = null

onMounted(async () => {
  await loadStats()
  await loadDailyStats()
  await nextTick()
  initPieChart()
})

onUnmounted(() => {
  trendChart?.dispose()
  pieChart?.dispose()
})

async function loadStats() {
  try {
    const res = await getDashboardStats()
    if (res.code === 200) {
      Object.assign(stats, res.data)
      recentPurchases.value = res.data.recentPurchases || []
    }
  } catch (e) {
    console.error('加载统计数据失败', e)
  }
}

async function loadDailyStats() {
  try {
    const res = await getDailyStats(chartDays.value)
    if (res.code === 200) {
      await nextTick()
      initTrendChart(res.data || [])
    }
  } catch (e) {
    console.error('加载每日统计失败', e)
  }
}

function initTrendChart(data) {
  if (!trendChartRef.value) return
  if (trendChart) trendChart.dispose()
  
  trendChart = echarts.init(trendChartRef.value)
  
  const dates = data.map(d => d.date)
  const users = data.map(d => d.newUsers || 0)
  const orders = data.map(d => d.newOrders || 0)
  const revenue = data.map(d => d.revenue || 0)
  
  trendChart.setOption({
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'rgba(15, 12, 40, 0.9)',
      borderColor: 'rgba(100, 80, 200, 0.3)',
      textStyle: { color: '#d4d0e8' }
    },
    legend: {
      data: ['新增用户', '新增订单', '收入(金币)'],
      textStyle: { color: '#a098b8' },
      top: 5
    },
    grid: {
      left: 50,
      right: 20,
      top: 45,
      bottom: 30
    },
    xAxis: {
      type: 'category',
      data: dates,
      axisLine: { lineStyle: { color: 'rgba(100, 80, 200, 0.2)' } },
      axisLabel: { color: '#8a80a8', fontSize: 11 }
    },
    yAxis: [
      {
        type: 'value',
        name: '数量',
        axisLine: { show: false },
        splitLine: { lineStyle: { color: 'rgba(100, 80, 200, 0.08)' } },
        axisLabel: { color: '#8a80a8' }
      },
      {
        type: 'value',
        name: '金币',
        axisLine: { show: false },
        splitLine: { show: false },
        axisLabel: { color: '#8a80a8' }
      }
    ],
    series: [
      {
        name: '新增用户',
        type: 'bar',
        data: users,
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: '#818cf8' },
            { offset: 1, color: '#6366f1' }
          ]),
          borderRadius: [4, 4, 0, 0]
        },
        barWidth: '25%'
      },
      {
        name: '新增订单',
        type: 'bar',
        data: orders,
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: '#34d399' },
            { offset: 1, color: '#10b981' }
          ]),
          borderRadius: [4, 4, 0, 0]
        },
        barWidth: '25%'
      },
      {
        name: '收入(金币)',
        type: 'line',
        yAxisIndex: 1,
        data: revenue,
        smooth: true,
        lineStyle: { color: '#f59e0b', width: 2 },
        itemStyle: { color: '#f59e0b' },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(245, 158, 11, 0.2)' },
            { offset: 1, color: 'rgba(245, 158, 11, 0)' }
          ])
        }
      }
    ]
  })
}

function initPieChart() {
  if (!pieChartRef.value) return
  
  pieChart = echarts.init(pieChartRef.value)
  
  pieChart.setOption({
    tooltip: {
      trigger: 'item',
      backgroundColor: 'rgba(15, 12, 40, 0.9)',
      borderColor: 'rgba(100, 80, 200, 0.3)',
      textStyle: { color: '#d4d0e8' }
    },
    series: [
      {
        type: 'pie',
        radius: ['40%', '70%'],
        center: ['50%', '55%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 6,
          borderColor: 'rgba(10, 8, 30, 0.8)',
          borderWidth: 2
        },
        label: {
          show: true,
          color: '#a098b8',
          fontSize: 11
        },
        data: [
              { value: stats.totalUsers || 100, name: '总用户', itemStyle: { color: '#818cf8' } },
          { value: stats.totalOrders || 50, name: '总订单', itemStyle: { color: '#34d399' } },
          { value: stats.todayNewUsers || 10, name: '今日新用户', itemStyle: { color: '#f59e0b' } },
          { value: stats.todayOrders || 5, name: '今日订单', itemStyle: { color: '#f472b6' } }
        ]
      }
    ]
  })
}

// 窗口resize
window.addEventListener('resize', () => {
  trendChart?.resize()
  pieChart?.resize()
})
</script>

<style scoped>
.dashboard {
  padding: 0;
}

.stat-cards {
  margin-bottom: 20px;
}

.stat-card {
  display: flex;
  align-items: center;
  padding: 24px 20px;
  border-radius: 12px;
  background: rgba(20, 16, 50, 0.6);
  border: 1px solid rgba(100, 80, 200, 0.15);
  transition: all 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
  border-color: rgba(100, 80, 200, 0.3);
  box-shadow: 0 4px 20px rgba(80, 50, 200, 0.1);
}

.stat-icon {
  font-size: 36px;
  margin-right: 16px;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  font-family: 'Courier New', monospace;
  background: linear-gradient(135deg, #a78bfa, #60a5fa);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.stat-label {
  font-size: 13px;
  color: #8a80a8;
  margin-top: 4px;
}

.chart-row {
  margin-bottom: 20px;
}

.chart-card {
  background: rgba(20, 16, 50, 0.6);
  border: 1px solid rgba(100, 80, 200, 0.15);
  border-radius: 12px;
  padding: 20px;
}

.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.chart-header h3 {
  margin: 0;
  font-size: 15px;
  color: #d4d0e8;
  font-weight: 600;
}

.chart-container {
  width: 100%;
  height: 320px;
}

.recent-section {
  margin-top: 0;
}

.gold-text {
  color: #f59e0b;
  font-weight: 600;
}

.pixel-table :deep(.el-table__header th) {
  background: rgba(30, 25, 60, 0.8) !important;
  color: #a098b8;
}

.pixel-table :deep(.el-table__row) {
  background: transparent;
}

.pixel-table :deep(.el-table__row:hover > td) {
  background: rgba(100, 80, 200, 0.08) !important;
}
</style>