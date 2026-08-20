import SwiftUI

struct FeatureMenuView: View {
    var body: some View {
        List {
            Section {
                destination("搜索", symbol: "magnifyingglass") { TransactionSearchView() }
                destination("订阅与分期", symbol: "repeat.circle") { RecurringHomeView() }
                destination("储蓄目标", symbol: "target") { SavingsGoalsView() }
            }
            Section("管理") {
                destination("账本管理", symbol: "books.vertical") { LedgerManagementView() }
                destination("分类管理", symbol: "square.grid.2x2") { CategoryManagementView() }
                destination("设置", symbol: "gear") { SettingsView() }
            }
        }
        .navigationTitle("更多")
    }

    private func destination<Destination: View>(_ title: String, symbol: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) { Label(title, systemImage: symbol) }
    }
}
