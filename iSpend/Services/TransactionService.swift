import Foundation
import SwiftData

@MainActor
enum TransactionService {
    enum ServiceError: LocalizedError {
        case invalidAmount, missingLedger, missingCategory, missingAccount, sameTransferAccount, saveFailed
        var errorDescription: String? { switch self { case .invalidAmount: "金额必须大于 0"; case .missingLedger: "请选择账本"; case .missingCategory: "请选择分类"; case .missingAccount: "请选择账户"; case .sameTransferAccount: "转入和转出账户不能相同"; case .saveFailed: "数据保存失败，请稍后重试" } }
    }

    struct Draft {
        var type: TransactionType; var amount: Decimal; var date: Date; var note: String; var currency: String; var tags: [String]; var isReimbursable: Bool; var receiptData: Data?; var ledger: Ledger?; var category: FinanceCategory?; var source: Account?; var destination: Account?
    }

    static func create(_ draft: Draft, in context: ModelContext) throws -> FinanceTransaction {
        try validate(draft)
        let item = FinanceTransaction(type: draft.type, amount: draft.amount, date: draft.date, note: draft.note, currency: draft.currency, tags: draft.tags, isReimbursable: draft.isReimbursable, receiptData: draft.receiptData, ledger: draft.ledger, category: draft.category, sourceAccount: draft.source, destinationAccount: draft.destination)
        apply(item); context.insert(item)
        do { try context.save(); return item } catch { rollback(item); context.delete(item); throw ServiceError.saveFailed }
    }

    static func update(_ item: FinanceTransaction, with draft: Draft, in context: ModelContext) throws {
        try validate(draft); rollback(item)
        let old = Draft(type: item.type, amount: item.amount, date: item.date, note: item.note, currency: item.currency, tags: item.tags, isReimbursable: item.isReimbursable, receiptData: item.receiptData, ledger: item.ledger, category: item.category, source: item.sourceAccount, destination: item.destinationAccount)
        item.typeRaw = draft.type.rawValue; item.amount = draft.amount; item.date = draft.date; item.note = draft.note; item.currency = draft.currency; item.tagsText = draft.tags.joined(separator: ","); item.isReimbursable = draft.isReimbursable; item.receiptData = draft.receiptData; item.ledger = draft.ledger; item.category = draft.category; item.sourceAccount = draft.source; item.destinationAccount = draft.destination; item.updatedAt = .now; apply(item)
        do { try context.save() } catch { rollback(item); restore(item, old); apply(item); throw ServiceError.saveFailed }
    }

    static func delete(_ item: FinanceTransaction, in context: ModelContext) throws {
        rollback(item); context.delete(item)
        do { try context.save() } catch { apply(item); throw ServiceError.saveFailed }
    }

    private static func validate(_ draft: Draft) throws {
        guard draft.amount > 0 else { throw ServiceError.invalidAmount }
        guard draft.ledger != nil else { throw ServiceError.missingLedger }
        switch draft.type {
        case .expense:
            guard draft.category != nil else { throw ServiceError.missingCategory }
            guard draft.source != nil else { throw ServiceError.missingAccount }
        case .income:
            guard draft.category != nil else { throw ServiceError.missingCategory }
            guard draft.destination != nil else { throw ServiceError.missingAccount }
        case .transfer:
            guard let source = draft.source, let destination = draft.destination else { throw ServiceError.missingAccount }
            guard source.id != destination.id else { throw ServiceError.sameTransferAccount }
        }
    }
    private static func apply(_ item: FinanceTransaction) { switch item.type { case .expense: item.sourceAccount?.balance -= item.amount; case .income: item.destinationAccount?.balance += item.amount; case .transfer: item.sourceAccount?.balance -= item.amount; item.destinationAccount?.balance += item.amount } }
    private static func rollback(_ item: FinanceTransaction) { switch item.type { case .expense: item.sourceAccount?.balance += item.amount; case .income: item.destinationAccount?.balance -= item.amount; case .transfer: item.sourceAccount?.balance += item.amount; item.destinationAccount?.balance -= item.amount } }
    private static func restore(_ item: FinanceTransaction, _ draft: Draft) { item.typeRaw = draft.type.rawValue; item.amount = draft.amount; item.date = draft.date; item.note = draft.note; item.currency = draft.currency; item.tagsText = draft.tags.joined(separator: ","); item.isReimbursable = draft.isReimbursable; item.receiptData = draft.receiptData; item.ledger = draft.ledger; item.category = draft.category; item.sourceAccount = draft.source; item.destinationAccount = draft.destination }
}
