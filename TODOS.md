# Eyescape TODOS

## v2 重定向后状态 (2026-05)

v2 不再做数字宠物，转向"屏幕数据 + 20-20-20 + 眼保健操"。
所有宠物相关 TODO 已标记 `[PARKED]` 并迁到底部 Parking Lot 节，等 v3+ 重新评估。

### 已完成 (claude/review-product-design-1lmOJ 分支)

- [x] **AnalyticsView 周计图标签歧义** — `dayLabels = ["M","Tu","W","Th","F","Sa","Su"]`，加了 per-bar 的 `accessibilityLabel`。
- [x] **AnalyticsView "This week" 伪按钮** — 改为静态 `LAST 7 DAYS` 标签，去掉了误导性的边框样式。
- [x] **HomeView 状态点 a11y** — SessionStatusBar 加 `accessibilityElement(children: .combine)` + 完整 accessibilityLabel。
- [x] **HomeView alerting 状态视觉区分** — 新 SessionStatusBar 在 alerting 时 amber dot 阴影从 0.6 升到 0.9 + 文案变为 "Time for a break"。
- [x] **HomeView 宠物部分** — 删除 petSection 和 PetMoodEngine 注入，替换为 stats grid + ExerciseCard + SessionStatusBar。
- [x] **handleBackground 接入 scenePhase** — 之前是 dead code，现在被 `Eyescape_appApp` 的 `.background/.inactive` 调用，alerting → confirmBreak 行为终于真正生效。
- [x] **PickupSession 模型** — 新增 SwiftData @Model，handleForeground/handleBackground 创建/关闭，<5s 视为误触丢弃。
- [x] **ScreenTimeAggregator + 单元测试** — 12 个测试 case，覆盖空数据/全合规/全违规/混合/跨日/开放 pickup 等。
- [x] **EyeExerciseLibrary + EyeExerciseSession** — 三种循证练习，全屏 sheet 运行。
- [x] **ScreenTimeAuthManager + Settings CTA** — Family Controls 授权包装 + Settings 页面"Connect"按钮。
- [x] **DeviceActivityReportExtension 源代码骨架** — `EyescapeReportExtension.swift / DailyActivityReport.swift / DailyActivityView.swift / Info.plist` 已就位，等 Xcode UI 创建 target。

## P0 — v2 发布前必须处理

- [ ] **Family Controls Xcode UI 设置** — 见 `docs/family-controls-application.md`：
  - 主 target 添加 Family Controls capability
  - 创建 DeviceActivityReportExtension target，导入已 staged 的 4 个文件
  - 配置 App Group `group.com.eyescape.shared`
  - AnalyticsView 嵌入 `DeviceActivityReport(.daily, filter:)`
- [ ] **Family Controls entitlement 申请** — 主 app + extension 同时提交，Account Holder 账号，预留 3-6 周。
- [ ] **真机 QA**(iPhone 14 Pro+ / iOS 17.2+ / 付费开发者账号 sideload)：
  - Settings → Connect → 系统授权弹窗
  - HomeView 4 个指标显示真实 PickupSession 派生数据
  - 启动 quickRest/palming/classicChinese 完整跑完 → EyeExerciseRecord 入库 → HomeView 计数 +1
  - 切换到 Insights → 周条形图标签为 M/Tu/W/Th/F/Sa/Su
  - 锁屏解锁 → PickupSession 闭合
  - alerting → 锁屏 → 重新打开 → BreakRecord 已记录 wasSkipped=false

## P1 — 实现前/上线前

- [ ] **SwiftData 迁移计划** — v1 用户升级到 v2，schema 多了 PetState（v1 已有，无变化）+ EyeExerciseRecord（v1 已有）+ PickupSession（v2 新增）。新增 model 在 SwiftData 自动 lightweight migration 下应该无痛，但发布前需要在装有 v1 build 数据的真机上做一次升级冒烟。
- [ ] **StoreKit 购买错误处理** — 订阅购买时网络失败/用户取消无 error handler。`do-catch StoreKitError`，展示失败提示 + 重试按钮。文件：`Features/StoreManager.swift`, `Views/PaywallView.swift`
- [ ] **全 app a11y 标签** — 已补 SessionStatusBar 和 AnalyticsView 周条形图。还缺：BreakView 跳过/完成按钮、SettingsView pill 选择器、PaywallView 价格行。

## P2 — 实现时注意

- [ ] **`startActivity()` 失败降级** — 用户在 iOS 设置关闭 Live Activity 权限时 `Activity.request()` throws，需要 `do-catch` + 自动降级到通知模式。文件：`Features/SessionManager.swift`
- [ ] **AnalyticsView 时间范围真实切换** — 当前是静态 `LAST 7 DAYS`，做成 Day/Week/Month segmented control 后才完整。
- [ ] **AI insights v2** — 当前的 `aiInsights` 是基于 Session.duration 的规则。换成基于 PickupSession + ExerciseRecord 的（"你晚上 8 点之后单次平均 35 分钟没休息" 之类）。
- [ ] **Onboarding 流程** — 首次启动一个 3-screen onboarding：解释 20-20-20 + 引导授权 Family Controls + 设定提醒间隔。当前用户直接落到 HomeView。

## Post-v2

- [ ] DeviceActivityMonitor extension（v2.2）— 让 20-20-20 提醒基于系统级使用时长，不再受限于 Eyescape 的前台时间。
- [ ] App-specific 护眼模式 — 选取使用最久的 3 个 app 作为重点提醒源。
- [ ] Streak 持续天数 + 晚间打卡推送
- [ ] Apple Watch companion
- [ ] Shortcut / Siri 集成
- [ ] Widget Home Screen（非 DI）

## Parking Lot — Pet 系统 (代码保留，UI 已下线)

宠物系统冷冻，未来如果发现"情感绑定"对留存帮助大于"严肃数据"才解冻。
代码保留：`Models/PetState.swift`, `Features/PetMoodEngine.swift`,
`Features/PetNotificationManager.swift`, `Views/PetView.swift`,
`Eyescape app/cat-pixel/`。

- [PARKED] PetView accessibilityLabel — moodLabel 中文映射
- [PARKED] HomeView 宠物对话气泡（已从 HomeView 移除）
- [PARKED] HomeView 侧边统计徽章（streak / exercise count）
- [PARKED] SettingsView 宠物名字输入框
- [PARKED] exsec-dev/pixel-cat 资产授权确认
- [PARKED] Live Activity 8h 续期与宠物像素图联动
- [PARKED] 宠物早晚定时通知
- [PARKED] PetMoodEngine 7 天幽灵期
- [PARKED] PetMoodEngine 单元测试

解冻条件：(a) 用户研究证明情感粘性 > 严肃数据展示对留存的影响，或
(b) 立项儿童版 Eyescape。
