@preconcurrency import SwiftData

enum iSpendSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Ledger.self, FinanceCategory.self, Account.self, FinanceTransaction.self, Budget.self, SavingsGoal.self, SavingsRecord.self, RecurringPayment.self, InstallmentPlan.self] }
}

enum iSpendMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [iSpendSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
