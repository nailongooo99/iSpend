import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UserNotifications

private enum ExportKind { case csv, json }

struct DataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data, .commaSeparatedText, .json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct SettingsView: View {
    @Query private var ledgers: [Ledger]
    @Query private var accounts: [Account]
    @Query private var transactions: [FinanceTransaction]
    @Query private var budgets: [Budget]
    @AppStorage("defaultLedgerID") private var defaultLedgerID = ""
    @AppStorage("defaultAccountID") private var defaultAccountID = ""
    @AppStorage("defaultCurrency") private var currency = "CNY"
    @AppStorage("saveAndContinue") private var saveAndContinue = false
    @AppStorage("rememberCategory") private var rememberCategory = true
    @AppStorage("rememberAccount") private var rememberAccount = true
    @AppStorage("haptics") private var haptics = true
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("hideAmounts") private var hideAmounts = false
    @AppStorage("budgetNotifications") private var budgetNotifications = false
    @AppStorage("subscriptionNotifications") private var subscriptionNotifications = false
    @AppStorage("savingsNotifications") private var savingsNotifications = false
    @AppStorage("liveActivityEnabled") private var liveActivityEnabled = false
    @AppStorage("liveActivityPeriod") private var liveActivityPeriod = LiveActivityPeriod.today.rawValue
    @AppStorage("liveActivityMetric") private var liveActivityMetric = LiveActivityMetric.expense.rawValue
    @State private var exportKind: ExportKind?
    @State private var exporting = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("通用") {
                Picker("默认账本", selection: $defaultLedgerID) { Text("自动").tag(""); ForEach(ledgers) { Text($0.name).tag($0.id.uuidString) } }
                Picker("默认账户", selection: $defaultAccountID) { Text("自动").tag(""); ForEach(accounts) { Text($0.name).tag($0.id.uuidString) } }
                Picker("默认币种", selection: $currency) { ForEach(["CNY", "USD", "EUR", "JPY"], id: \.self) { Text($0) } }
            }
            Section("记账") {
                Toggle("保存后继续记账", isOn: $saveAndContinue); Toggle("记住上一次分类", isOn: $rememberCategory); Toggle("记住上一次账户", isOn: $rememberAccount); Toggle("记账震动反馈", isOn: $haptics)
            }
            Section("显示") {
                Picker("外观", selection: $appearance) { Text("跟随系统").tag("system"); Text("浅色").tag("light"); Text("深色").tag("dark") }
                Toggle("隐藏金额", isOn: $hideAmounts)
            }
            Section("通知") {
                Toggle("预算提醒", isOn: $budgetNotifications).onChange(of: budgetNotifications) { requestNotificationsIfNeeded() }
                Toggle("订阅提醒", isOn: $subscriptionNotifications).onChange(of: subscriptionNotifications) { requestNotificationsIfNeeded() }
                Toggle("储蓄提醒", isOn: $savingsNotifications).onChange(of: savingsNotifications) { requestNotificationsIfNeeded() }
            }
            Section("灵动岛与实时活动") {
                Toggle("启用实时活动状态", isOn: $liveActivityEnabled).onChange(of: liveActivityEnabled) { syncLiveActivity() }
                Picker("收支总览周期", selection: $liveActivityPeriod) { ForEach(LiveActivityPeriod.allCases) { Text($0.title).tag($0.rawValue) } }.disabled(!liveActivityEnabled).onChange(of: liveActivityPeriod) { syncLiveActivity() }
                Picker("主要显示数据", selection: $liveActivityMetric) { ForEach(LiveActivityMetric.allCases) { Label($0.title, systemImage: $0.symbolName).tag($0.rawValue) } }.disabled(!liveActivityEnabled).onChange(of: liveActivityMetric) { syncLiveActivity() }
                Text("支持灵动岛的 iPhone 会显示紧凑与展开视图；其他支持设备可在锁屏查看。交易或预算变化时会自动更新。").font(.footnote).foregroundStyle(.secondary)
            }
            Section("数据") {
                Button("导出 CSV", systemImage: "tablecells") { exportKind = .csv; exporting = true }
                Button("导出 JSON", systemImage: "curlybraces") { exportKind = .json; exporting = true }
            }
            Section("关于") {
                LabeledContent("iSpend", value: "我花，我掌控")
                LabeledContent("版本", value: versionDescription)
                Link("隐私政策", destination: privacyURL)
                NavigationLink("开源许可") { List { Text("iSpend 仅使用 Apple 系统框架，不包含第三方运行时依赖。") }.navigationTitle("开源许可") }
            }
        }
        .navigationTitle("设置")
        .fileExporter(isPresented: $exporting, document: DataDocument(data: exportData), contentType: exportKind == .csv ? .commaSeparatedText : .json, defaultFilename: exportKind == .csv ? "iSpend-transactions.csv" : "iSpend-backup.json") { result in if case .failure(let error) = result { errorMessage = error.localizedDescription } }
        .alert("操作失败", isPresented: errorPresented) { } message: { Text(errorMessage ?? "") }
    }

    private var errorPresented: Binding<Bool> { Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }) }
    private var privacyURL: URL { URL(string: "https://github.com/nailongooo99/iSpend/blob/main/PRIVACY.md") ?? URL(fileURLWithPath: "/") }
    private var exportData: Data { exportKind == .csv ? ExportService.csv(transactions) : ExportService.json(transactions) }
    private var versionDescription: String { "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"))" }
    private func requestNotificationsIfNeeded() {
        guard budgetNotifications || subscriptionNotifications || savingsNotifications else { return }
        Task { do { _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) } catch { errorMessage = error.localizedDescription } }
    }
    private func syncLiveActivity() {
        let enabled = liveActivityEnabled
        let period = LiveActivityPeriod(rawValue: liveActivityPeriod) ?? .today
        let metric = LiveActivityMetric(rawValue: liveActivityMetric) ?? .expense
        Task {
            if enabled {
                do { try await LiveActivityService.sync(transactions: transactions, budgets: budgets, period: period, metric: metric, currencyCode: currency) }
                catch { liveActivityEnabled = false; errorMessage = error.localizedDescription }
            } else { await LiveActivityService.endAll() }
        }
    }
}
