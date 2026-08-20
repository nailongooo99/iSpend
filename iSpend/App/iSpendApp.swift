import SwiftUI
import SwiftData

@main
struct iSpendApp: App {
    private let container: ModelContainer
    init() {
        do { container = try ModelContainer(for: iSpendSchemaV1.self, migrationPlan: iSpendMigrationPlan.self) }
        catch { fatalError("无法创建 iSpend 数据库：\(error.localizedDescription)") }
    }
    var body: some Scene { WindowGroup { RootView() }.modelContainer(container) }
}
