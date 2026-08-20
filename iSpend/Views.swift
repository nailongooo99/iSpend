import SwiftUI
import SwiftData
import Charts

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var ledgers: [Ledger]
    @State private var selected = 0
    var body: some View {
        TabView(selection: $selected) {
            LedgerView().tabItem { Label("账单", systemImage: "list.bullet.rectangle") }.tag(0)
            AccountsView().tabItem { Label("资产", systemImage: "square.stack.3d.up") }.tag(1)
            BudgetView().tabItem { Label("预算", systemImage: "wallet.bifold") }.tag(2)
            StatisticsView().tabItem { Label("统计", systemImage: "chart.bar.fill") }.tag(3)
        }.tint(.accentColor).task { if ledgers.isEmpty { context.insert(Ledger()); SeedData.categories.forEach { context.insert($0) }; context.insert(Account(name: "现金", type: .cash)); try? context.save() } }
    }
}

struct LedgerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var accounts: [Account]
    @Query private var categories: [Category]
    @Query private var ledgers: [Ledger]
    @State private var showingAdd = false; @State private var search = ""; @State private var editing: Transaction?
    private var filtered: [Transaction] { search.isEmpty ? transactions : transactions.filter { $0.note.localizedCaseInsensitiveContains(search) || $0.category?.name.contains(search) == true } }
    private var expenses: Decimal { filtered.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    private var income: Decimal { filtered.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } }
    var body: some View { NavigationStack { List { Section { VStack(alignment: .leading, spacing: 14) { Text("本月概览").font(.headline); Text(AppFormat.money(expenses)).font(.largeTitle.bold()).monospacedDigit(); HStack { Metric(title: "收入", value: income, color: .green); Metric(title: "结余", value: income - expenses, color: .primary) } }.padding(.vertical, 8) }.listRowBackground(Color.clear)
            if filtered.isEmpty { ContentUnavailableView("还没有账单", systemImage: "tray", description: Text("点击右下角 + 记录第一笔消费")) } else { ForEach(groupedKeys, id: \.self) { key in Section { ForEach(filtered.filter { Calendar.current.isDate($0.date, inSameDayAs: key) }) { tx in TransactionRow(transaction: tx).contentShape(Rectangle()).onTapGesture { editing = tx }.swipeActions { Button(role: .destructive) { context.delete(tx); try? context.save() } label: { Label("删除", systemImage: "trash") } } } } header: { Text(key, format: AppFormat.day) } } }
        }.navigationTitle("账单").searchable(text: $search, prompt: "搜索备注或分类").toolbar { ToolbarItem(placement: .topBarTrailing) { Menu { Text("当前账本：\(ledgers.first?.name ?? "默认账本")"); Button("设置") {} } label: { Image(systemName: "ellipsis.circle") } } }.overlay(alignment: .bottomTrailing) { Button { showingAdd = true } label: { Image(systemName: "plus").font(.title2.bold()).foregroundStyle(.white).frame(width: 58, height: 58).background(Color.accentColor, in: Circle()).shadow(radius: 8, y: 4) }.padding(20).accessibilityLabel("新增交易") }.sheet(isPresented: $showingAdd) { AddTransactionView() }.sheet(item: $editing) { TransactionDetailView(transaction: $0) } } }
    private var groupedKeys: [Date] { let days = filtered.map { Calendar.current.startOfDay(for: $0.date) }; return Array(Set(days)).sorted(by: >) }
}

struct Metric: View { let title: String; let value: Decimal; let color: Color; var body: some View { VStack(alignment: .leading) { Text(title).font(.caption).foregroundStyle(.secondary); Text(AppFormat.money(value)).font(.headline).foregroundStyle(color).monospacedDigit() } } }
struct TransactionRow: View { let transaction: Transaction; var body: some View { HStack(spacing: 12) { Image(systemName: transaction.category?.symbolName ?? "arrow.left.arrow.right").foregroundStyle(Color.accentColor).frame(width: 34, height: 34).background(Color.secondary.opacity(0.12), in: Circle()); VStack(alignment: .leading) { Text(transaction.category?.name ?? "转账"); Text(transaction.note.isEmpty ? transaction.date.formatted(AppFormat.time) : transaction.note).font(.caption).foregroundStyle(.secondary) }; Spacer(); Text((transaction.type == .expense ? "−" : transaction.type == .income ? "+" : "") + AppFormat.money(transaction.amount)).foregroundStyle(transaction.type == .income ? .green : .primary).monospacedDigit() } } }

struct AddTransactionView: View { @Environment(\.dismiss) private var dismiss; @Environment(\.modelContext) private var context; @Query private var ledgers: [Ledger]; @Query private var accounts: [Account]; @Query private var categories: [Category]; @State private var type: TransactionType = .expense; @State private var amount = ""; @State private var note = ""; @State private var category: Category?; @State private var account: Account?; @State private var date = Date(); var body: some View { NavigationStack { Form { Picker("类型", selection: $type) { Text("支出").tag(TransactionType.expense); Text("收入").tag(TransactionType.income); Text("转账").tag(TransactionType.transfer) }.pickerStyle(.segmented); Section("金额") { TextField("0.00", text: $amount).keyboardType(.decimalPad); DatePicker("时间", selection: $date) }; if type != .transfer { Section("分类") { Picker("分类", selection: $category) { Text("请选择").tag(nil as Category?); ForEach(categories.filter { $0.type == (type == .income ? .income : .expense) }) { Text($0.name).tag(Optional($0)) } } } }; Section("账户") { Picker(type == .income ? "入账账户" : "支付账户", selection: $account) { ForEach(accounts) { Text($0.name).tag(Optional($0)) } }; TextField("备注", text: $note) } }.navigationTitle("快速记账").toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("保存") { save() }.disabled(Decimal(amount) == nil || Decimal(amount) == 0) } } } }
    private func save() { guard let value = Decimal(amount), value > 0, let ledger = ledgers.first else { return }; let tx = Transaction(type: type, amount: value, date: date, note: note, ledger: ledger, category: category, source: type == .income ? nil : account, destination: type == .income ? account : nil); context.insert(tx); if type == .expense { account?.balance -= value }; if type == .income { account?.balance += value }; try? context.save(); dismiss() }
}

struct TransactionDetailView: View { @Environment(\.dismiss) private var dismiss; @Environment(\.modelContext) private var context; let transaction: Transaction; @State private var note = ""; var body: some View { Form { LabeledContent("金额", value: AppFormat.money(transaction.amount)); LabeledContent("类型", value: transaction.type == .expense ? "支出" : transaction.type == .income ? "收入" : "转账"); LabeledContent("分类", value: transaction.category?.name ?? "转账"); LabeledContent("时间", value: transaction.date.formatted(AppFormat.day)); TextField("备注", text: $note) }.navigationTitle("交易详情").toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { transaction.note = note; transaction.updatedAt = .now; try? context.save(); dismiss() } } }.onAppear { note = transaction.note } } }

struct AccountsView: View { @Query private var accounts: [Account]; var body: some View { NavigationStack { List { if accounts.isEmpty { ContentUnavailableView("还没有账户", systemImage: "square.stack.3d.up") }; ForEach(accounts) { a in HStack { Image(systemName: "creditcard"); Text(a.name); Spacer(); Text(AppFormat.money(a.balance)).monospacedDigit() } } }.navigationTitle("资产") } } }
struct BudgetView: View { @Query private var budgets: [Budget]; @Query private var transactions: [Transaction]; var body: some View { NavigationStack { List { if budgets.isEmpty { ContentUnavailableView("还没有设置预算", systemImage: "chart.bar.xaxis") } else { ForEach(budgets) { b in let used = transactions.filter { $0.type == .expense && ($0.category == b.category || b.category == nil) }.reduce(0) { $0 + $1.amount }; VStack(alignment: .leading) { HStack { Text(b.category?.name ?? "总预算").font(.headline); Spacer(); Text(AppFormat.money(used) + " / " + AppFormat.money(b.amount)).monospacedDigit() }; ProgressView(value: min(NSDecimalNumber(decimal: used).doubleValue / max(NSDecimalNumber(decimal: b.amount).doubleValue, 1), 1)); Text(used > b.amount ? "超支" : "剩余 " + AppFormat.money(b.amount - used)).font(.caption).foregroundStyle(used > b.amount ? .red : .secondary) }.padding(.vertical, 8) } } }.navigationTitle("预算") } } }
struct StatisticsView: View { @Query private var transactions: [Transaction]; var body: some View { NavigationStack { let expenses = transactions.filter { $0.type == .expense }; VStack(alignment: .leading, spacing: 20) { Text("统计").font(.largeTitle.bold()); HStack { Metric(title: "支出", value: expenses.reduce(0) { $0 + $1.amount }, color: .primary); Metric(title: "收入", value: transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }, color: .green) }; Chart(expenses, id: \.id) { t in BarMark(x: .value("日期", t.date, unit: .day), y: .value("金额", NSDecimalNumber(decimal: t.amount).doubleValue)).foregroundStyle(.tint) }.frame(height: 240); Spacer() }.padding().navigationTitle("统计") } } }
