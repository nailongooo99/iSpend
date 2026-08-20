import SwiftUI
import SwiftData

@main
struct iSpendApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(for: [Ledger.self, Category.self, Account.self, Transaction.self, Budget.self, SavingsGoal.self, SavingsRecord.self, RecurringPayment.self, InstallmentPlan.self])
    }
}
