import SwiftUI
import SwiftData

enum AppTab: Hashable { case ledger, accounts, budget, statistics }

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedTab = AppTab.ledger
    @State private var seedError: String?
    @AppStorage("appearance") private var appearance = "system"
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
        .alert("初始化失败", isPresented: .constant(seedError != nil)) { Button("好") { seedError = nil } } message: { Text(seedError ?? "未知错误") }
    }
}
