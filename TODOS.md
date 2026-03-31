# Eyescape TODOS

## Design — 设计审查发现

- [ ] **全 app a11y 标签** — 所有界面缺少 `accessibilityLabel`/`accessibilityHint`。最关键: AnalyticsView 条状图 ForEach、HomeView 状态点、ActiveCard 按钮。影响: App Store 审核可能拒绝，VoiceOver 用户完全无法使用。
- [ ] **AnalyticsView 周计图标签歧义** — `AnalyticsView.swift:204` `dayLabels = ["M","T","W","T","F","S","S"]` 周四和周二都显示 "T"，周六周日都是 "S"。改为 `["M","Tu","W","Th","F","Sa","Su"]` 或用 `DateFormatter` 自动生成。
- [ ] **HomeView alerting 状态视觉区分** — `isAlerting` 时 session card 和 active 完全相同。BreakView sheet 弹出前用户没有预期。可以加 amber 边框闪烁或改变卡片文案。
- [ ] **AnalyticsView "This week" 标签** — 右上角 "This week" 标签外观像可点击的筛选器但不可交互，容易造成误解。要么改为静态文字，要么真正实现时间范围切换。

## P1 — 实现前必须处理

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
