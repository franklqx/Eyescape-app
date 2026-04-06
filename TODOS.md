# Eyescape TODOS

## Design — v2 宠物系统设计决策 (2026-03-31 审查通过)

- [ ] **PetView accessibilityLabel** — `.accessibilityElement(children: .ignore)` + `.accessibilityLabel("\(petName), \(moodLabel). 今日护眼 \(score) 分")`。moodLabel 映射: happy→"开心" / okay→"还不错" / tired→"有点累" / sad→"不开心" / ghost→"需要关注" / sleeping→"在睡觉"。
- [ ] **HomeView 宠物对话气泡** — `PetMoodEngine.currentMessage: String`，点击宠物 `onTapGesture` toggle `@State showBubble`。Week 2-3 实现。
- [ ] **HomeView 侧边统计徽章** — 右上角：🔥 streak天 + 👁 眼保健操次数。Week 1 加 streak 徽章，眼保健操 Week 5 后激活。
- [ ] **SettingsView 宠物名字输入框** — `TextField` 读写 `PetState.name`，默认值 "Mochi"。Week 2 加入设置页。

## Design — 设计审查发现（既有 app）

- [ ] **全 app a11y 标签** — 所有界面缺少 `accessibilityLabel`/`accessibilityHint`。最关键: AnalyticsView 条状图 ForEach、HomeView 状态点、ActiveCard 按钮。影响: App Store 审核可能拒绝，VoiceOver 用户完全无法使用。
- [ ] **AnalyticsView 周计图标签歧义** — `AnalyticsView.swift:204` `dayLabels = ["M","T","W","T","F","S","S"]` 周四和周二都显示 "T"，周六周日都是 "S"。改为 `["M","Tu","W","Th","F","Sa","Su"]` 或用 `DateFormatter` 自动生成。
- [ ] **HomeView alerting 状态视觉区分** — `isAlerting` 时 session card 和 active 完全相同。BreakView sheet 弹出前用户没有预期。可以加 amber 边框闪烁或改变卡片文案。
- [ ] **AnalyticsView "This week" 标签** — 右上角 "This week" 标签外观像可点击的筛选器但不可交互，容易造成误解。要么改为静态文字，要么真正实现时间范围切换。

## P0 — Week 0 Gate（宠物功能 Week 1 开始前必须关闭）

- [ ] **exsec-dev/pixel-cat 资产授权确认** — 确认 GitHub repo 的商用许可（MIT/Apache？）。若无商用许可则保留现有 `PetView.swift` 手写精灵系统并扩展颜色变体。这是整个视觉方向的 gate，必须在 Week 1 第一行代码前关闭。
- [ ] **Live Activity 8h 续期策略决策** — 建议：每次 session 开始时 `Activity.end()` + `Activity.request()`（重启 LA）。需真机验证（iPhone 14 Pro+, iOS 17.2+）。DEBUG flag 将 8h 缩为 5min 测试。若系统限流则降级：8h 后 DI 消失，用户手动重启 session。相关文件：`SessionManager.swift`。（此项已在 Post-Launch 节有提及，升级为 P0）
- [ ] **宠物早晚定时通知** — `UNUserNotificationCenter` 两条定时通知：早上唤起（默认 09:00，文案由猫心情决定，如 "Mochi 想你了，来做护眼操吧！"）+ 晚上睡觉（默认 22:00，固定文案）。SettingsView 加时间选择器。通知权限申请在 onboarding 第一步，以"猫会每天叫你"为申请理由。相关文件：新建 `PetNotificationManager.swift`。
- [ ] **PetMoodEngine 7天幽灵期** — 新用户安装后 7 天内，PetMoodEngine 强制输出 `okay` 或 `happy`，不展示 `sad`/`ghost`/`tired`，防止冷启动负反馈在情感绑定建立前触发卸载。实现：`PetState.createdAt` + `if Date().timeIntervalSince(createdAt) < 7 * 86400 → return .okay`。

## P1 — 实现前必须处理

- [ ] **PetMoodEngine 单元测试** — `PetMoodEngine` 是纯逻辑，必须有单元测试覆盖以下场景：(1) triggered=0 时不崩溃（除零保护），(2) 7天幽灵期边界（第 7 天），(3) sleeping 覆盖（22:01 本地时间），(4) exercise cap 验证（10次 = 5次相同），(5) 完整分数路径。测试文件：`Eyescape appTests/PetMoodEngineTests.swift`。配合 Week 1 实现同步写。

- [ ] **handleBackground 回归测试** — `SessionManager.handleBackground()` 新增 `.alerting → confirmBreak()` 分支。必须有回归测试验证 `.active → performPause()` 路径未受影响。防止无声 bug：用户 session 中锁屏后 break 被误记录为完成。

- [ ] **SwiftData 迁移计划 (v2 发布前)** — v2 新增 `PetState` SwiftData model。发布时如果没有 `VersionedSchema` + `SchemaMigrationPlan`，v1 老用户升级后 app 启动崩溃（store incompatibility error）。修复: 在 `Eyescape_appApp.swift` 中配置 `ModelContainer(for: schema, migrationPlan:)`，迁移策略为 `.addModels([PetState.self])`。当前测试阶段不紧迫，正式发布前 P1。

- [ ] **StoreKit 购买错误处理** — 订阅购买时网络失败/用户取消无 error handler，用户看到空白屏。需要 `do-catch StoreKitError`，展示失败提示 + 重试按钮。相关文件：`StoreKitManager.swift`, `PaywallView.swift`

## P2 — 实现时注意

- [ ] **startActivity() 失败降级** — 当用户在设置里关闭 Eyescape 的 Live Activity 权限时，`Activity.request()` 会 throw 错误，需要 `do-catch` 捕获并自动降级到通知模式。相关文件：`SessionManager.swift`
  
## Post-Launch / v2

- [ ] 历史统计 UI（图表、连续天数）— SwiftData 数据模型已就绪
- [ ] Theme 定制
- [ ] Apple Watch companion
- [ ] Shortcut / Siri 集成
- [ ] Widget Home Screen（非 DI）

- [ ] **Paywall product fetch 失败处理** — StoreKit 网络失败时 Paywall 显示空白。需要 async product fetch + loading state + 本地硬编码价格 fallback + retry 按钮。相关文件：`PaywallView.swift`, `StoreKitManager.swift`
- [ ] **8h Live Activity 续期验证** — `end()+startActivity()` 续期逻辑需要在真机 (iPhone 14 Pro+, iOS 17.2+) 上验证。可用 DEBUG flag 将 8h 缩短为 5min 测试。如失败，降级方案：8h 后 DI 消失，用户手动重启 session。
