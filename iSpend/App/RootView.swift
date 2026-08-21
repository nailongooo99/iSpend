import SwiftUI
import SwiftData

enum AppTab: Hashable { case ledger, accounts, budget, statistics }

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var transactions: [FinanceTransaction]
    @Query private var budgets: [Budget]
    @State private var selectedTab = AppTab.ledger
    @State private var seedError: String?
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("liveActivityEnabled") private var liveActivityEnabled = false
    @AppStorage("liveActivityPeriod") private var liveActivityPeriod = LiveActivityPeriod.today.rawValue
    @AppStorage("liveActivityMetric") private var liveActivityMetric = LiveActivityMetric.expense.rawValue
    var body: some View {
        TabView(selection: $selectedTab) {
            LedgerHomeView().tabItem { Label("账单", systemImage: "list.bullet.rectangle") }.tag(AppTab.ledger)
            AccountsHomeView().tabItem { Label("资产", systemImage: "square.stack.3d.up") }.tag(AppTab.accounts)
            BudgetHomeView().tabItem { Label("预算", systemImage: "wallet.bifold") }.tag(AppTab.budget)
            StatisticsHomeView().tabItem { Label("统计", systemImage: "chart.bar.fill") }.tag(AppTab.statistics)
        }
        .tint(.accentColor)
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
        .task { do { try SeedData.insertIfNeeded(in: context); try RecurringService.generateDueTransactions(in: context) } catch { seedError = error.localizedDescription } }
        .task(id: liveActivitySignature) {
            guard liveActivityEnabled else { return }
            do { try await LiveActivityService.sync(transactions: transactions, budgets: budgets, period: LiveActivityPeriod(rawValue: liveActivityPeriod) ?? .today, metric: LiveActivityMetric(rawValue: liveActivityMetric) ?? .expense) }
            catch { seedError = error.localizedDescription }
        }
        .alert("初始化失败", isPresented: .constant(seedError != nil)) { Button("好") { seedError = nil } } message: { Text(seedError ?? "未知错误") }
    }
    private var liveActivitySignature: String {
        let latestUpdate = transactions.map(\.updatedAt).max()?.timeIntervalSince1970 ?? 0
        let budgetValue = budgets.reduce(Decimal.zero) { $0 + $1.amount }
        return "\(transactions.count)-\(latestUpdate)-\(budgetValue)-\(liveActivityPeriod)-\(liveActivityMetric)-\(liveActivityEnabled)"
    }
}
