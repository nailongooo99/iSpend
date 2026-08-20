import SwiftUI
import SwiftData

@main
struct iSpendApp: App {
    private let container: ModelContainer
    init() {
        do {
            let schema = Schema(versionedSchema: iSpendSchemaV1.self)
            container = try ModelContainer(for: schema, migrationPlan: iSpendMigrationPlan.self)
        }
        catch { fatalError("无法创建 iSpend 数据库：\(error.localizedDescription)") }
    }
    var body: some Scene { WindowGroup { RootView() }.modelContainer(container) }
}
