import ActivityKit
import Foundation

enum LiveActivityPeriod: String, CaseIterable, Identifiable, Codable {
    case today, week, month, year
    var id: Self { self }
    var title: String { switch self { case .today: "今日收支"; case .week: "本周收支"; case .month: "本月收支"; case .year: "今年收支" } }
    var calendarComponent: Calendar.Component { switch self { case .today: .day; case .week: .weekOfYear; case .month: .month; case .year: .year } }
}

enum LiveActivityMetric: String, CaseIterable, Identifiable, Codable {
    case expense, income, balance, budget
    var id: Self { self }
    var title: String { switch self { case .expense: "支出"; case .income: "收入"; case .balance: "结余"; case .budget: "预算" } }
    var symbolName: String { switch self { case .expense: "arrow.up.right"; case .income: "arrow.down.left"; case .balance: "equal"; case .budget: "wallet.bifold" } }
}

struct SpendingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var expense: Double
        var income: Double
        var balance: Double
        var budgetRemaining: Double
        var periodTitle: String
        var metricRawValue: String
        var updatedAt: Date

        var metric: LiveActivityMetric { LiveActivityMetric(rawValue: metricRawValue) ?? .expense }
        var preferredValue: Double { switch metric { case .expense: expense; case .income: income; case .balance: balance; case .budget: budgetRemaining } }
    }

    var currencyCode: String
}
