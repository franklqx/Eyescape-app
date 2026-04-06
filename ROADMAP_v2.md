# Eyescape v2 Roadmap

> **Product Vision**: Eyescape is a digital pet + eye health companion. Your pet's mood reflects how well you've been protecting your eyes. Take breaks, do exercises, keep your pet happy.

---

## Phase 1 — Pet System (v2.0)
**目标**: 情感粘性。让用户每天打开 app 看宠物状态。

### 核心功能
- [ ] **数字宠物 (Digital Pet)**
  - 像素风格小动物，琥珀色调
  - 情绪系统: Happy / Okay / Tired / Sad (4 levels)
  - 情绪 = 当日护眼分数计算 (break compliance rate)
  - 每日分数: 完成 break ×10分, 跳过 break -5分, 连续天数 bonus

- [ ] **宠物动画状态**
  - Idle: 小幅呼吸动画
  - Happy: 轻微跳动 + 闪光
  - Tired: 慢速眨眼 + 耷拉
  - Sad: 眼泪 pixel drop 动画
  - Exercise: 专属运动动画 (配合 eye exercise)

- [ ] **眼部练习 (Eye Exercises)**
  - 休息时提供 3 种可解锁练习
  - 完成练习 → 宠物 +5 情绪值 + 特效动画
  - 练习类型: 20-20-20 / 眼球滚动 / 远近交替

- [ ] **DI 宠物头像**
  - 灵动岛 compact leading: 宠物像素头像 (替换 amber dot)
  - 宠物状态与 DI 颜色联动 (happy=amber, sad=蓝灰)

- [ ] **HomeView 重设计**
  - 移除 Start Session 按钮
  - 宠物居中显示，占主要视觉面积
  - 宠物下方: 今日分数 + 情绪标签
  - 底部: 当前 session 状态 (小卡片)

- [ ] **Session 自动启动**
  - 打开 app = 自动开始 session (不需要手动 Start)
  - 关闭 app / 锁屏 = session 持续后台运行
  - 首次启动: 引导页说明机制

### 数据模型扩展
```swift
@Model class PetState {
    var name: String           // 用户起名
    var totalScore: Int        // 历史累计分
    var streak: Int            // 连续天数
    var lastActiveDate: Date
    var unlockedExercises: [String]  // 已解锁练习 ID
    var mood: PetMood          // computed from today's score
}

enum PetMood: Int, Codable {
    case sad = 0, tired = 1, okay = 2, happy = 3
}
```

### 里程碑
| 周 | 目标 |
|----|------|
| Week 1 | 宠物像素画 + 基础动画 (SwiftUI Canvas / SpriteKit) |
| Week 2 | 情绪计算逻辑 + PetState SwiftData 模型 |
| Week 3 | HomeView 重设计 + 自动 Session 启动 |
| Week 4 | 眼部练习 UI + 宠物互动动画 |
| Week 5 | DI 宠物头像 + TestFlight Beta |

---

## Phase 2 — Pro 功能升级 + 打磨 (v2.1)
**目标**: 提升 Pro 转化，完善核心体验。

- [ ] **宠物起名** — 首次启动引导，Pro 用户可改名
- [ ] **宠物皮肤解锁** — Pro: 2 额外皮肤 (夜间版 / 彩虹版)
- [ ] **Pro 设置 Slider 实时预览** — 调整间隔时宠物实时反应
- [ ] **Analytics v2** — 宠物心情趋势图 + 周/月视图
- [ ] **连续天数 Streak** — 专属 UI + 打破提醒通知
- [ ] **BreakView 练习选择** — 休息时显示练习卡片
- [ ] **a11y 全面补齐** — TODOS.md 中所有 a11y 项
- [ ] **AnalyticsView bar label 修复** — ["M","Tu","W","Th","F","Sa","Su"]
- [ ] **StoreKit 错误处理** — 网络失败提示 + 重试 (TODOS.md P1)

---

## Phase 3 — Screen Time API 监控 (v3.0)
**目标**: 无感监控，自动护眼。需要 Apple Family Controls 授权。

> ⚠️ **风险**: Screen Time API 需要向 Apple 申请特殊 entitlement，审核周期不确定。v1/v2 期间并行申请，获批后启动 Phase 3。

- [ ] **DeviceActivityMonitor Extension**
  - 监控用户使用手机时长
  - 每 20 分钟 (可配置) 触发护眼提醒
  - 不需要 app 在前台

- [ ] **App-specific 护眼模式** (v3 Pro)
  - 选择特定 app (抖音/微信等) 触发更频繁提醒
  - 宠物对高风险使用有专属反应动画

- [ ] **背景监控**
  - Session 不依赖 app 打开
  - 真正的"无感"护眼

### Apple 授权申请
- 申请时间: v1 上架后立即提交
- 预计等待: 2-8 周
- 降级方案: Phase 3 不可用时，v1/v2 模式继续正常工作

---

## Focus App — 独立项目
**时间线**: Eyescape v2 Beta 期间并行开发

- 简洁的 +/- 任务列表
- 番茄钟 / 深度工作计时
- 每周 / 每月任务完成统计
- 可能共享 Eyescape 护眼提醒逻辑

---

## v1 待处理 (上线前)
来自 TODOS.md — 上线前必须解决:

| 优先级 | 项目 | 文件 |
|--------|------|------|
| P1 | StoreKit 购买错误处理 | StoreKitManager.swift, PaywallView.swift |
| P2 | startActivity() 失败降级 | SessionManager.swift |
| Design | a11y 标签补全 | 所有 Views |
| Design | Bar chart label 歧义修复 | AnalyticsView.swift:204 |

---

## 技术选型备忘

| 功能 | 技术 | 备注 |
|------|------|------|
| 宠物动画 | SwiftUI Canvas + withAnimation | 简单帧动画；复杂动画用 SpriteKit |
| 像素图资产 | .png @1x/@2x/@3x | Aseprite 导出，Asset Catalog |
| 情绪计算 | Pure Swift, no framework | 每日 break records 聚合 |
| 分数持久化 | SwiftData PetState | 已有 ModelContainer |
| DI 像素头像 | SwiftUI Image (pixel asset) | ActivityKit content state 传 mood enum |
| Screen Time | DeviceActivityMonitor Extension | Phase 3，需 Apple 授权 |
