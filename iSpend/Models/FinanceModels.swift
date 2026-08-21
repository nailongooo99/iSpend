import Foundation
import SwiftData

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case expense, income, transfer
    var id: Self { self }
    var title: String { switch self { case .expense: "支出"; case .income: "收入"; case .transfer: "转账" } }
}

enum CategoryType: String, Codable, CaseIterable { case expense, income }
enum BudgetPeriod: String, Codable, CaseIterable, Identifiable {
    case month, year
    var id: Self { self }
    var title: String { self == .month ? "月预算" : "年预算" }
}
enum AccountType: String, Codable, CaseIterable, Identifiable {
    case cash, debitCard, creditCard, alipay, wechat, investment, fund, stock, providentFund, otherAsset, loan, otherLiability
    var id: Self { self }
    var title: String { switch self { case .cash: "现金"; case .debitCard: "储蓄卡"; case .creditCard: "信用卡"; case .alipay: "支付宝"; case .wechat: "微信"; case .investment: "投资账户"; case .fund: "基金"; case .stock: "股票"; case .providentFund: "公积金"; case .otherAsset: "其他资产"; case .loan: "贷款"; case .otherLiability: "其他负债" } }
    var isLiability: Bool { self == .creditCard || self == .loan || self == .otherLiability }
    var symbol: String { switch self { case .cash: "banknote"; case .debitCard, .creditCard: "creditcard"; case .alipay: "a.circle.fill"; case .wechat: "w.circle.fill"; case .investment, .fund, .stock: "chart.line.uptrend.xyaxis"; case .providentFund, .otherAsset: "building.columns"; case .loan, .otherLiability: "exclamationmark.arrow.circlepath" } }
}
enum SavingsGoalType: String, Codable, CaseIterable, Identifiable { case flexible, periodic; var id: Self { self }; var title: String { self == .flexible ? "自由存钱" : "定期存钱" } }
enum Frequency: String, Codable, CaseIterable, Identifiable { case daily, weekly, monthly, yearly; var id: Self { self }; var title: String { switch self { case .daily: "每天"; case .weekly: "每周"; case .monthly: "每月"; case .yearly: "每年" } } }
enum RecurringKind: String, Codable, CaseIterable, Identifiable { case subscription, custom; var id: Self { self }; var title: String { self == .subscription ? "订阅" : "自订周期" } }

@Model final class Ledger {
    var id: UUID
    var name: String
    var symbolName: String
    var colorHex: String
    var currency: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \FinanceTransaction.ledger) var transactions: [FinanceTransaction]
    @Relationship(deleteRule: .cascade, inverse: \Budget.ledger) var budgets: [Budget]
    init(name: String = "默认账本", symbolName: String = "book.closed", colorHex: String = "#007AFF", currency: String = "CNY") {
        id = UUID(); self.name = name; self.symbolName = symbolName; self.colorHex = colorHex; self.currency = currency; createdAt = .now; transactions = []; budgets = []
    }
}

@Model final class FinanceCategory {
    static var hierarchySeparator: Character { "/" }
    var id: UUID
    var name: String
    var symbolName: String
    var colorHex: String
    var typeRaw: String
    var sortOrder: Int
    var isEnabled: Bool
    @Relationship(deleteRule: .nullify, inverse: \FinanceTransaction.category) var transactions: [FinanceTransaction]
    init(name: String, symbolName: String, colorHex: String, type: CategoryType, sortOrder: Int = 0, isEnabled: Bool = true) {
        id = UUID(); self.name = name; self.symbolName = symbolName; self.colorHex = colorHex; typeRaw = type.rawValue; self.sortOrder = sortOrder; self.isEnabled = isEnabled; transactions = []
    }
    var type: CategoryType { CategoryType(rawValue: typeRaw) ?? .expense }
    var parentName: String? {
        let parts = name.split(separator: Self.hierarchySeparator, maxSplits: 1).map(String.init)
        return parts.count == 2 ? parts[0] : nil
    }
    var displayName: String {
        name.split(separator: Self.hierarchySeparator, maxSplits: 1).last.map(String.init) ?? name
    }
    var pathDisplayName: String { name.replacing("/", with: " › ") }
    var isSubcategory: Bool { parentName != nil }
    static func storageName(_ displayName: String, parentName: String?) -> String {
        guard let parentName, !parentName.isEmpty else { return displayName }
        return parentName + String(hierarchySeparator) + displayName
    }
}

@Model final class Account {
    var id: UUID
    var name: String
    var typeRaw: String
    var balance: Decimal
    var currency: String
    var institution: String
    var maskedNumber: String
    var creditLimit: Decimal
    var billingDay: Int?
    var repaymentDay: Int?
    var symbolName: String
    var colorHex: String
    var note: String
    var createdAt: Date
    init(name: String, type: AccountType = .cash, balance: Decimal = 0, currency: String = "CNY", institution: String = "", maskedNumber: String = "", creditLimit: Decimal = 0, billingDay: Int? = nil, repaymentDay: Int? = nil, symbolName: String? = nil, colorHex: String = "#007AFF", note: String = "") {
        id = UUID(); self.name = name; typeRaw = type.rawValue; self.balance = balance; self.currency = currency; self.institution = institution; self.maskedNumber = maskedNumber; self.creditLimit = creditLimit; self.billingDay = billingDay; self.repaymentDay = repaymentDay; self.symbolName = symbolName ?? type.symbol; self.colorHex = colorHex; self.note = note; createdAt = .now
    }
    var type: AccountType { AccountType(rawValue: typeRaw) ?? .cash }
}

@Model final class FinanceTransaction {
    var id: UUID
    var typeRaw: String
    var amount: Decimal
    var date: Date
    var note: String
    var currency: String
    var tagsText: String
    var isReimbursable: Bool
    var isReimbursed: Bool
    @Attribute(.externalStorage) var receiptData: Data?
    var ledger: Ledger?
    var category: FinanceCategory?
    var sourceAccount: Account?
    var destinationAccount: Account?
    var recurringSourceID: UUID?
    var createdAt: Date
    var updatedAt: Date
    init(type: TransactionType, amount: Decimal, date: Date = .now, note: String = "", currency: String = "CNY", tags: [String] = [], isReimbursable: Bool = false, receiptData: Data? = nil, ledger: Ledger? = nil, category: FinanceCategory? = nil, sourceAccount: Account? = nil, destinationAccount: Account? = nil, recurringSourceID: UUID? = nil) {
        id = UUID(); typeRaw = type.rawValue; self.amount = amount; self.date = date; self.note = note; self.currency = currency; tagsText = tags.joined(separator: ","); self.isReimbursable = isReimbursable; isReimbursed = false; self.receiptData = receiptData; self.ledger = ledger; self.category = category; self.sourceAccount = sourceAccount; self.destinationAccount = destinationAccount; self.recurringSourceID = recurringSourceID; createdAt = .now; updatedAt = .now
    }
    var type: TransactionType { TransactionType(rawValue: typeRaw) ?? .expense }
    var tags: [String] { tagsText.split(separator: ",").map(String.init) }
}

@Model final class Budget {
    var id: UUID
    var amount: Decimal
    var periodRaw: String
    var startDate: Date
    var isNotificationEnabled: Bool
    var ledger: Ledger?
    var category: FinanceCategory?
    init(amount: Decimal, period: BudgetPeriod = .month, startDate: Date = .now, isNotificationEnabled: Bool = false, ledger: Ledger? = nil, category: FinanceCategory? = nil) {
        id = UUID(); self.amount = amount; periodRaw = period.rawValue; self.startDate = startDate; self.isNotificationEnabled = isNotificationEnabled; self.ledger = ledger; self.category = category
    }
    var period: BudgetPeriod { BudgetPeriod(rawValue: periodRaw) ?? .month }
}

@Model final class SavingsGoal {
    var id: UUID; var name: String; var emoji: String; var targetAmount: Decimal; var currentAmount: Decimal; var typeRaw: String; var startDate: Date; var targetDate: Date?; var colorHex: String; var frequencyRaw: String; var periodicAmount: Decimal
    @Relationship(deleteRule: .cascade, inverse: \SavingsRecord.goal) var records: [SavingsRecord]
    init(name: String, emoji: String = "🎯", targetAmount: Decimal, currentAmount: Decimal = 0, type: SavingsGoalType = .flexible, startDate: Date = .now, targetDate: Date? = nil, colorHex: String = "#AF52DE", frequency: Frequency = .monthly, periodicAmount: Decimal = 0) {
        id = UUID(); self.name = name; self.emoji = emoji; self.targetAmount = targetAmount; self.currentAmount = currentAmount; typeRaw = type.rawValue; self.startDate = startDate; self.targetDate = targetDate; self.colorHex = colorHex; frequencyRaw = frequency.rawValue; self.periodicAmount = periodicAmount; records = []
    }
    var type: SavingsGoalType { SavingsGoalType(rawValue: typeRaw) ?? .flexible }
    var frequency: Frequency { Frequency(rawValue: frequencyRaw) ?? .monthly }
}

@Model final class SavingsRecord {
    var id: UUID; var amount: Decimal; var date: Date; var note: String; var goal: SavingsGoal?
    init(amount: Decimal, date: Date = .now, note: String = "", goal: SavingsGoal? = nil) { id = UUID(); self.amount = amount; self.date = date; self.note = note; self.goal = goal }
}

@Model final class RecurringPayment {
    var id: UUID; var kindRaw: String; var name: String; var amount: Decimal; var currency: String; var frequencyRaw: String; var interval: Int; var nextPaymentDate: Date; var symbolName: String; var note: String; var autoCreateTransaction: Bool; var notificationDaysBefore: Int; var lastGeneratedDate: Date?; var account: Account?; var category: FinanceCategory?
    init(kind: RecurringKind = .subscription, name: String, amount: Decimal, currency: String = "CNY", frequency: Frequency = .monthly, interval: Int = 1, nextPaymentDate: Date = .now, symbolName: String = "repeat.circle", note: String = "", autoCreateTransaction: Bool = false, notificationDaysBefore: Int = 1, account: Account? = nil, category: FinanceCategory? = nil) {
        id = UUID(); kindRaw = kind.rawValue; self.name = name; self.amount = amount; self.currency = currency; frequencyRaw = frequency.rawValue; self.interval = interval; self.nextPaymentDate = nextPaymentDate; self.symbolName = symbolName; self.note = note; self.autoCreateTransaction = autoCreateTransaction; self.notificationDaysBefore = notificationDaysBefore; self.account = account; self.category = category
    }
    var kind: RecurringKind { RecurringKind(rawValue: kindRaw) ?? .subscription }
    var frequency: Frequency { Frequency(rawValue: frequencyRaw) ?? .monthly }
}

@Model final class InstallmentPlan {
    var id: UUID; var name: String; var totalAmount: Decimal; var downPayment: Decimal; var installmentCount: Int; var paidInstallments: Int; var installmentAmount: Decimal; var startDate: Date; var nextPaymentDate: Date; var fee: Decimal; var note: String; var account: Account?
    init(name: String, totalAmount: Decimal, downPayment: Decimal = 0, installmentCount: Int, paidInstallments: Int = 0, installmentAmount: Decimal, startDate: Date = .now, nextPaymentDate: Date = .now, fee: Decimal = 0, note: String = "", account: Account? = nil) {
        id = UUID(); self.name = name; self.totalAmount = totalAmount; self.downPayment = downPayment; self.installmentCount = installmentCount; self.paidInstallments = paidInstallments; self.installmentAmount = installmentAmount; self.startDate = startDate; self.nextPaymentDate = nextPaymentDate; self.fee = fee; self.note = note; self.account = account
    }
}
