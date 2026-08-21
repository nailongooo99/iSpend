import ActivityKit
import Foundation

@MainActor
enum LiveActivityService {
    enum LiveActivityError: LocalizedError {
        case unavailable
        var errorDescription: String? { "系统未允许 iSpend 使用实时活动，请在系统设置中开启“实时活动”。" }
    }

    static func sync(transactions: [FinanceTransaction], budgets: [Budget], period: LiveActivityPeriod, metric: LiveActivityMetric, currencyCode: String = "CNY") async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { throw LiveActivityError.unavailable }
        let state = makeState(transactions: transactions, budgets: budgets, period: period, metric: metric)
        let content = ActivityContent(state: state, staleDate: Calendar.current.date(byAdding: .hour, value: 6, to: .now), relevanceScore: 50)
        if Activity<SpendingActivityAttributes>.activities.isEmpty {
            _ = try Activity.request(attributes: SpendingActivityAttributes(currencyCode: currencyCode), content: content, pushType: nil)
        } else {
            for activity in Activity<SpendingActivityAttributes>.activities { await activity.update(content) }
        }
    }

    static func endAll() async {
        for activity in Activity<SpendingActivityAttributes>.activities { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    static func makeState(transactions: [FinanceTransaction], budgets: [Budget], period: LiveActivityPeriod, metric: LiveActivityMetric, now: Date = .now) -> SpendingActivityAttributes.ContentState {
        let interval = Calendar.current.dateInterval(of: period.calendarComponent, for: now)
        let current = transactions.filter { interval?.contains($0.date) == true }
        let expense = FinanceCalculator.total(current, type: .expense)
        let income = FinanceCalculator.total(current, type: .income)
        let matchingBudgets = budgets.filter { budget in
            switch period { case .month: budget.period == .month; case .year: budget.period == .year; case .today, .week: budget.period == .month }
        }
        let budgetTotal = matchingBudgets.filter { $0.category == nil }.reduce(Decimal.zero) { $0 + $1.amount }
        return SpendingActivityAttributes.ContentState(expense: expense.doubleValue, income: income.doubleValue, balance: (income - expense).doubleValue, budgetRemaining: (budgetTotal - expense).doubleValue, periodTitle: period.title, metricRawValue: metric.rawValue, updatedAt: now)
    }
}
