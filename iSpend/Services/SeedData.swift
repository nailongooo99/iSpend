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
            ("娱乐/游戏", "gamecontroller", "#AF52DE", "expense"), ("娱乐/影视音乐", "play.rectangle", "#AF52DE", "expense"), ("娱乐/演出展览", "ticket", "#AF52DE", "expense"),
            ("服饰/衣服", "tshirt", "#FF9F0A", "expense"), ("服饰/鞋包", "handbag", "#FF9F0A", "expense"), ("服饰/配饰", "sunglasses", "#FF9F0A", "expense"),
            ("日用/清洁用品", "bubbles.and.sparkles", "#FFD60A", "expense"), ("日用/家居用品", "lamp.table", "#FFD60A", "expense"), ("日用/厨卫用品", "frying.pan", "#FFD60A", "expense"),
            ("数码/手机电脑", "laptopcomputer.and.iphone", "#5AC8FA", "expense"), ("数码/配件", "cable.connector", "#5AC8FA", "expense"), ("数码/维修", "wrench.and.screwdriver", "#5AC8FA", "expense"),
            ("美妆/彩妆", "paintbrush", "#FF2D55", "expense"), ("美妆/香水", "water.waves", "#FF2D55", "expense"), ("美妆/美容服务", "sparkles", "#FF2D55", "expense"),
            ("护肤/面部护理", "face.smiling", "#FF6482", "expense"), ("护肤/身体护理", "figure.mind.and.body", "#FF6482", "expense"), ("护肤/洗护", "shower", "#FF6482", "expense"),
            ("应用软件/订阅", "repeat.circle", "#5856D6", "expense"), ("应用软件/买断软件", "app.badge.checkmark", "#5856D6", "expense"), ("应用软件/云服务", "icloud", "#5856D6", "expense"),
            ("医疗/药品", "pills", "#FF3B30", "expense"), ("医疗/门诊", "stethoscope", "#FF3B30", "expense"), ("医疗/体检", "heart.text.square", "#FF3B30", "expense"), ("医疗/牙科", "cross.case", "#FF3B30", "expense"),
            ("通讯/手机话费", "iphone", "#32ADE6", "expense"), ("通讯/宽带", "wifi", "#32ADE6", "expense"), ("通讯/流量", "antenna.radiowaves.left.and.right", "#32ADE6", "expense"),
            ("汽车/加油充电", "fuelpump", "#64D2FF", "expense"), ("汽车/停车", "parkingsign", "#64D2FF", "expense"), ("汽车/保养维修", "wrench.adjustable", "#64D2FF", "expense"), ("汽车/路桥费", "road.lanes", "#64D2FF", "expense"),
            ("学习/书籍", "books.vertical", "#00C7BE", "expense"), ("学习/课程", "graduationcap", "#00C7BE", "expense"), ("学习/考试", "doc.text", "#00C7BE", "expense"), ("学习/文具", "pencil.and.ruler", "#00C7BE", "expense"),
            ("办公/办公用品", "printer", "#8E8E93", "expense"), ("办公/差旅", "suitcase.rolling", "#8E8E93", "expense"), ("办公/服务费", "person.crop.circle.badge.checkmark", "#8E8E93", "expense"),
            ("运动/健身", "dumbbell", "#30D158", "expense"), ("运动/运动装备", "figure.run", "#30D158", "expense"), ("运动/户外", "mountain.2", "#30D158", "expense"),
            ("社交/聚会", "person.3", "#BF5AF2", "expense"), ("社交/请客", "fork.knife", "#BF5AF2", "expense"), ("社交/礼物", "gift", "#BF5AF2", "expense"),
            ("人情/红包礼金", "envelope", "#FF375F", "expense"), ("人情/孝敬长辈", "figure.2.and.child.holdinghands", "#FF375F", "expense"), ("人情/公益捐赠", "heart", "#FF375F", "expense"),
            ("育儿/奶粉辅食", "takeoutbag.and.cup.and.straw", "#FFCC00", "expense"), ("育儿/教育", "figure.and.child.holdinghands", "#FFCC00", "expense"), ("育儿/玩具用品", "teddybear", "#FFCC00", "expense"), ("育儿/医疗", "cross.case", "#FFCC00", "expense"),
            ("旅行/住宿", "bed.double", "#0A84FF", "expense"), ("旅行/交通", "airplane", "#0A84FF", "expense"), ("旅行/景点门票", "ticket", "#0A84FF", "expense"), ("旅行/当地消费", "map", "#0A84FF", "expense"),
            ("宠物/食品", "takeoutbag.and.cup.and.straw", "#AC8E68", "expense"), ("宠物/用品", "pawprint", "#AC8E68", "expense"), ("宠物/医疗", "cross.case", "#AC8E68", "expense"), ("宠物/美容寄养", "house", "#AC8E68", "expense"),
            ("保险/医疗保险", "cross.case", "#5E5CE6", "expense"), ("保险/车险", "car", "#5E5CE6", "expense"), ("保险/寿险", "person.badge.shield.checkmark", "#5E5CE6", "expense"), ("保险/财产保险", "house", "#5E5CE6", "expense"),
            ("税费/个人所得税", "person.text.rectangle", "#8E8E93", "expense"), ("税费/手续费", "percent", "#8E8E93", "expense"), ("税费/行政费用", "building.columns", "#8E8E93", "expense"),
            ("其他/遗失损失", "exclamationmark.triangle", "#8E8E93", "expense"), ("其他/无法归类", "ellipsis", "#8E8E93", "expense"),
            ("工资/基本工资", "banknote", "#30D158", "income"), ("工资/补贴", "wallet.bifold", "#30D158", "income"), ("工资/加班费", "clock.badge.checkmark", "#30D158", "income"),
            ("奖金/年终奖", "trophy", "#30D158", "income"), ("奖金/绩效奖金", "medal", "#30D158", "income"),
            ("兼职/劳务报酬", "briefcase", "#30D158", "income"), ("兼职/稿费", "pencil.line", "#30D158", "income"),
            ("理财/利息", "percent", "#30D158", "income"), ("理财/投资收益", "chart.line.uptrend.xyaxis", "#30D158", "income"), ("理财/股息分红", "chart.bar", "#30D158", "income"),
            ("退款/购物退款", "cart.badge.minus", "#30D158", "income"), ("退款/押金退还", "arrow.uturn.backward.circle", "#30D158", "income"),
            ("红包/亲友红包", "giftcard", "#30D158", "income"), ("红包/活动奖励", "party.popper", "#30D158", "income"),
            ("报销/差旅报销", "airplane", "#30D158", "income"), ("报销/日常报销", "doc.text", "#30D158", "income"),
            ("其他收入/出售闲置", "shippingbox", "#30D158", "income"), ("其他收入/意外所得", "sparkles", "#30D158", "income")
        ]
        for (index, child) in children.enumerated() where !existingNames.contains(child.0) {
            context.insert(FinanceCategory(name: child.0, symbolName: child.1, colorHex: child.2, type: child.3 == "income" ? .income : .expense, sortOrder: 1_000 + index))
        }
        try context.save()
    }
}
