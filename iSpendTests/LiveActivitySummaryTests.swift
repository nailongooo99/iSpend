import Foundation
import Testing
@testable import iSpend

@MainActor
struct LiveActivitySummaryTests {
    @Test func summaryUsesSelectedPeriodAndMetric() {
        let now = Date.now
        let expense = FinanceTransaction(type: .expense, amount: 80, date: now)
        let income = FinanceTransaction(type: .income, amount: 200, date: now)
        let old = FinanceTransaction(type: .expense, amount: 999, date: Calendar.current.date(byAdding: .year, value: -2, to: now) ?? now)
        let budget = Budget(amount: 500, period: .month)
        let state = LiveActivityService.makeState(transactions: [expense, income, old], budgets: [budget], period: .month, metric: .balance, now: now)
        #expect(state.expense == 80)
        #expect(state.income == 200)
        #expect(state.balance == 120)
        #expect(state.budgetRemaining == 420)
        #expect(state.metric == .balance)
    }
}
