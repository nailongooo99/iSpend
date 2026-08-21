# iSpend

> 我花，我掌控。

iSpend 是一款使用 Swift 6、SwiftUI 与 SwiftData 编写的原生 iOS 个人财务应用。它遵循系统交互习惯，以几秒内完成记账为核心，同时让账户、预算与统计保持实时一致。

## 功能

- 账单按日期分组、月份切换、收支日历、全文搜索
- 支出、收入与转账快速记账，自带支持四则运算的财务键盘
- 交易详情、编辑、复制、报销标记与安全删除
- 账户与净资产管理；交易新增、编辑或删除时自动校正余额
- 月/年总预算和分类预算，使用金额由真实交易动态计算
- Swift Charts 收支分类环形图与分类交易明细
- 多账本、自定义分类、储蓄目标、订阅、自订周期与分期
- 支持一级与二级分类，快速记账可按层级精确选择
- 账单支持周、月、年、自定义时间范围及交易类型筛选
- 支持 ActivityKit 实时活动与灵动岛收支总览
- 订阅到期自动生成账单并避免同一周期重复生成
- CSV/JSON 数据导出、深色模式、Dynamic Type 与基础 VoiceOver

## 技术栈

- Swift 6（严格并发检查）
- SwiftUI / Observation
- SwiftData（版本化 Schema）
- Charts / PhotosUI / UserNotifications
- iOS 18+
- XcodeGen 生成工程，无第三方运行时依赖

## 工程结构

```text
iSpend/
├── App/          App 入口与 TabView
├── Models/       SwiftData 模型与迁移 Schema
├── Services/     交易一致性、统计、格式化、导出、自动账单
├── Components/   可复用原生 SwiftUI 组件
└── Features/     Ledger / Accounts / Budget / Statistics / Savings / Recurring / Management
```

## 本地开发

需要 macOS、Xcode 16.4+ 与 XcodeGen：

```bash
brew install xcodegen
xcodegen generate
open iSpend.xcodeproj
```

## 构建未签名 IPA

打开仓库的 **Actions → Build unsigned IPA → Run workflow**。工作流会：

1. 在 GitHub 托管的 macOS runner 上生成 Xcode 工程；
2. 以 `CODE_SIGNING_ALLOWED=NO` 构建真机 Release App；
3. 打包并上传 `iSpend-unsigned-ipa` Artifact。

未签名 IPA 不能直接安装到普通 iPhone，需要使用你自己的证书重新签名。它适合后续签名、侧载工具处理或产物检查。由于 iSpend 包含实时活动 Widget Extension，签名工具必须同时重签主 App 和 `PlugIns/iSpendLiveActivity.appex`，并为两者生成匹配的描述文件；不支持嵌套扩展重签的工具仍会导致 iOS 拒绝安装。设备系统版本必须为 iOS 18 或更高版本。

## 数据与隐私

iSpend 的财务数据默认仅存储在设备本地，不包含广告或分析 SDK。详情见 [PRIVACY.md](PRIVACY.md)。

## License

MIT

完整版本变化见 [CHANGELOG.md](CHANGELOG.md)。
