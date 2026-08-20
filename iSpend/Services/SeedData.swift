import SwiftData

@MainActor
enum SeedData {
    static func insertIfNeeded(in context: ModelContext) throws {
        guard try context.fetchCount(FetchDescriptor<Ledger>()) == 0 else { return }
        let ledger = Ledger(); context.insert(ledger)
        context.insert(Account(name: "现金", type: .cash, balance: 0, colorHex: "#30D158"))
        context.insert(Account(name: "微信余额", type: .wechat, balance: 0, colorHex: "#07C160"))
        let expenses: [(String, String, String)] = [
            ("餐饮", "fork.knife", "#FF6B5E"), ("购物", "cart", "#FF9500"), ("服饰", "tshirt", "#FF9F0A"), ("日用", "basket", "#FFD60A"), ("数码", "iphone", "#5AC8FA"),
            ("美妆", "wand.and.stars", "#FF2D55"), ("护肤", "drop", "#FF6482"), ("应用软件", "app.badge", "#5856D6"), ("住房", "house", "#007AFF"), ("交通", "car", "#34C759"),
            ("娱乐", "gamecontroller", "#AF52DE"), ("医疗", "cross.case", "#FF3B30"), ("通讯", "phone", "#32ADE6"), ("汽车", "steeringwheel", "#64D2FF"), ("学习", "book", "#00C7BE"),
            ("办公", "briefcase", "#8E8E93"), ("运动", "figure.run", "#30D158"), ("社交", "person.2", "#BF5AF2"), ("人情", "gift", "#FF375F"), ("育儿", "figure.and.child.holdinghands", "#FFCC00"),
            ("旅行", "airplane", "#0A84FF"), ("宠物", "pawprint", "#AC8E68"), ("保险", "shield", "#5E5CE6"), ("税费", "doc.text", "#8E8E93"), ("其他", "ellipsis", "#8E8E93")
        ]
        for (index, item) in expenses.enumerated() { context.insert(FinanceCategory(name: item.0, symbolName: item.1, colorHex: item.2, type: .expense, sortOrder: index)) }
        let incomes: [(String, String)] = [("工资", "banknote"), ("奖金", "trophy"), ("兼职", "briefcase"), ("理财", "chart.line.uptrend.xyaxis"), ("退款", "arrow.uturn.backward.circle"), ("红包", "giftcard"), ("报销", "doc.text"), ("其他收入", "ellipsis")]
        for (index, item) in incomes.enumerated() { context.insert(FinanceCategory(name: item.0, symbolName: item.1, colorHex: "#30D158", type: .income, sortOrder: index)) }
        try context.save()
    }
}
