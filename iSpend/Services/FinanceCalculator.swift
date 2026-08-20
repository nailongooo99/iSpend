import Foundation

enum FinanceCalculator {
    static func interval(containing date: Date, period: BudgetPeriod, calendar: Calendar = .current) -> DateInterval? { calendar.dateInterval(of: period == .month ? .month : .year, for: date) }
    static func transactions(_ transactions: [FinanceTransaction], in date: Date, period: BudgetPeriod = .month) -> [FinanceTransaction] {
        guard let interval = interval(containing: date, period: period) else { return [] }
        return transactions.filter { interval.contains($0.date) }
    }
    static func total(_ transactions: [FinanceTransaction], type: TransactionType) -> Decimal { transactions.filter { $0.type == type }.reduce(0) { $0 + $1.amount } }
    static func used(_ budget: Budget, transactions: [FinanceTransaction], viewedDate: Date) -> Decimal {
        guard let interval = interval(containing: viewedDate, period: budget.period) else { return 0 }
        return transactions.filter { $0.type == .expense && interval.contains($0.date) && (budget.ledger == nil || $0.ledger?.id == budget.ledger?.id) && (budget.category == nil || $0.category?.id == budget.category?.id) }.reduce(0) { $0 + $1.amount }
    }
}

struct CategoryTotal: Identifiable {
    let id: UUID; let category: FinanceCategory; let amount: Decimal
}
