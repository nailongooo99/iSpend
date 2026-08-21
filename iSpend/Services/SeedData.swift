import SwiftData

@MainActor
enum SeedData {
    static func insertIfNeeded(in context: ModelContext) throws {
        if try context.fetchCount(FetchDescriptor<Ledger>()) == 0 { context.insert(Ledger()) }
        if try context.fetchCount(FetchDescriptor<Account>()) == 0 {
            context.insert(Account(name: "现金", type: .cash, balance: 0, colorHex: "#30D158"))
            context.insert(Account(name: "微信余额", type: .wechat, balance: 0, colorHex: "#07C160"))
        }
        let existingNames = Set(try context.fetch(FetchDescriptor<FinanceCategory>()).map(\.name))
        let expenses: [(String, String, String)] = [
            ("餐饮", "fork.knife", "#FF6B5E"), ("购物", "cart", "#FF9500"), ("服饰", "tshirt", "#FF9F0A"), ("日用", "basket", "#FFD60A"), ("数码", "iphone", "#5AC8FA"),
            ("美妆", "wand.and.stars", "#FF2D55"), ("护肤", "drop", "#FF6482"), ("应用软件", "app.badge", "#5856D6"), ("住房", "house", "#007AFF"), ("交通", "car", "#34C759"),
            ("娱乐", "gamecontroller", "#AF52DE"), ("医疗", "cross.case", "#FF3B30"), ("通讯", "phone", "#32ADE6"), ("汽车", "steeringwheel", "#64D2FF"), ("学习", "book", "#00C7BE"),
            ("办公", "briefcase", "#8E8E93"), ("运动", "figure.run", "#30D158"), ("社交", "person.2", "#BF5AF2"), ("人情", "gift", "#FF375F"), ("育儿", "figure.and.child.holdinghands", "#FFCC00"),
            ("旅行", "airplane", "#0A84FF"), ("宠物", "pawprint", "#AC8E68"), ("保险", "shield", "#5E5CE6"), ("税费", "doc.text", "#8E8E93"), ("其他", "ellipsis", "#8E8E93")
        ]
        for (index, item) in expenses.enumerated() where !existingNames.contains(item.0) { context.insert(FinanceCategory(name: item.0, symbolName: item.1, colorHex: item.2, type: .expense, sortOrder: index)) }
        let incomes: [(String, String)] = [("工资", "banknote"), ("奖金", "trophy"), ("兼职", "briefcase"), ("理财", "chart.line.uptrend.xyaxis"), ("退款", "arrow.uturn.backward.circle"), ("红包", "giftcard"), ("报销", "doc.text"), ("其他收入", "ellipsis")]
        for (index, item) in incomes.enumerated() where !existingNames.contains(item.0) { context.insert(FinanceCategory(name: item.0, symbolName: item.1, colorHex: "#30D158", type: .income, sortOrder: index)) }
        let children: [(String, String, String, String)] = [
            ("餐饮/早餐", "cup.and.saucer", "#FF6B5E", "expense"), ("餐饮/午餐", "takeoutbag.and.cup.and.straw", "#FF6B5E", "expense"), ("餐饮/晚餐", "fork.knife", "#FF6B5E", "expense"), ("餐饮/饮品", "mug", "#FF6B5E", "expense"),
            ("购物/网购", "shippingbox", "#FF9500", "expense"), ("购物/超市", "basket", "#FF9500", "expense"),
            ("交通/公交地铁", "tram", "#34C759", "expense"), ("交通/打车", "car.side", "#34C759", "expense"), ("交通/火车机票", "airplane", "#34C759", "expense"),
            ("住房/房租", "house", "#007AFF", "expense"), ("住房/水电燃气", "bolt", "#007AFF", "expense"), ("住房/物业", "building.2", "#007AFF", "expense"),
            ("娱乐/游戏", "gamecontroller", "#AF52DE", "expense"), ("娱乐/影视音乐", "play.rectangle", "#AF52DE", "expense"),
            ("工资/基本工资", "banknote", "#30D158", "income"), ("工资/补贴", "wallet.bifold", "#30D158", "income"), ("理财/利息", "percent", "#30D158", "income"), ("理财/投资收益", "chart.line.uptrend.xyaxis", "#30D158", "income")
        ]
        for (index, child) in children.enumerated() where !existingNames.contains(child.0) {
            context.insert(FinanceCategory(name: child.0, symbolName: child.1, colorHex: child.2, type: child.3 == "income" ? .income : .expense, sortOrder: 1_000 + index))
        }
        try context.save()
    }
}
