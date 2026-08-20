import Foundation
import SwiftData

@MainActor
enum RecurringService {
    static func generateDueTransactions(in context: ModelContext) throws {
        let payments = try context.fetch(FetchDescriptor<RecurringPayment>()).filter { $0.autoCreateTransaction && $0.nextPaymentDate <= .now }
        let ledgers = try context.fetch(FetchDescriptor<Ledger>())
        guard let ledger = ledgers.first else { return }
        for payment in payments {
            let alreadyGenerated = payment.lastGeneratedDate.map { Calendar.current.isDate($0, inSameDayAs: payment.nextPaymentDate) } ?? false
            guard !alreadyGenerated, let account = payment.account else { continue }
            let draft = TransactionService.Draft(type: .expense, amount: payment.amount, date: payment.nextPaymentDate, note: payment.name, currency: payment.currency, tags: ["自动账单"], isReimbursable: false, receiptData: nil, ledger: ledger, category: payment.category, source: account, destination: nil)
            let item = try TransactionService.create(draft, in: context); item.recurringSourceID = payment.id; payment.lastGeneratedDate = payment.nextPaymentDate
            payment.nextPaymentDate = nextDate(after: payment.nextPaymentDate, frequency: payment.frequency, interval: payment.interval)
        }
        try context.save()
    }
    private static func nextDate(after date: Date, frequency: Frequency, interval: Int) -> Date { let component: Calendar.Component = switch frequency { case .daily: .day; case .weekly: .weekOfYear; case .monthly: .month; case .yearly: .year }; return Calendar.current.date(byAdding: component, value: interval, to: date) ?? date }
}
