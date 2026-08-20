import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let transaction: FinanceTransaction
    @State private var editing = false
    @State private var confirmingDelete = false
    @State private var errorMessage: String?
    var body: some View {
        List {
            Section { VStack(spacing: 12) { CategoryIcon(category: transaction.category, size: 58); AmountText(amount: transaction.amount, currency: transaction.currency, type: transaction.type, font: .largeTitle.bold()); Text(transaction.category?.name ?? transaction.type.title).foregroundStyle(.secondary) }.frame(maxWidth: .infinity).padding() }
            Section("交易信息") { LabeledContent("类型", value: transaction.type.title); LabeledContent("账户", value: accountText); LabeledContent("时间", value: transaction.date.formatted(DateFormats.full)); LabeledContent("账本", value: transaction.ledger?.name ?? "—"); if !transaction.note.isEmpty { LabeledContent("备注", value: transaction.note) }; if !transaction.tags.isEmpty { LabeledContent("标签", value: transaction.tags.joined(separator: "、")) }; LabeledContent("报销状态", value: transaction.isReimbursable ? (transaction.isReimbursed ? "已报销" : "待报销") : "不报销") }
            if let data = transaction.receiptData, let image = UIImage(data: data) { Section("账单图片") { Image(uiImage: image).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 12)) } }
            Section("记录") { LabeledContent("创建时间", value: transaction.createdAt.formatted(DateFormats.full)); LabeledContent("修改时间", value: transaction.updatedAt.formatted(DateFormats.full)) }
            Section { Button("删除交易", systemImage: "trash", role: .destructive) { confirmingDelete = true }.frame(maxWidth: .infinity) }
        }.navigationTitle("交易详情").toolbar { Button("编辑") { editing = true } }.sheet(isPresented: $editing) { TransactionEditorView(transaction: transaction) }.confirmationDialog("删除这笔交易？", isPresented: $confirmingDelete) { Button("删除", role: .destructive) { do { try TransactionService.delete(transaction, in: context); dismiss() } catch { errorMessage = error.localizedDescription } } }.alert("删除失败", isPresented: .constant(errorMessage != nil)) { Button("好") { errorMessage = nil } } message: { Text(errorMessage ?? "") }
    }
    private var accountText: String { switch transaction.type { case .expense: transaction.sourceAccount?.name ?? "—"; case .income: transaction.destinationAccount?.name ?? "—"; case .transfer: "\(transaction.sourceAccount?.name ?? "—") → \(transaction.destinationAccount?.name ?? "—")" } }
}

struct TransactionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var ledgers: [Ledger]; @Query private var accounts: [Account]; @Query(sort: \FinanceCategory.sortOrder) private var categories: [FinanceCategory]
    let transaction: FinanceTransaction
    @State private var type: TransactionType; @State private var amount: String; @State private var date: Date; @State private var note: String; @State private var ledger: Ledger?; @State private var category: FinanceCategory?; @State private var source: Account?; @State private var destination: Account?; @State private var reimbursable: Bool; @State private var errorMessage: String?
    init(transaction: FinanceTransaction) { self.transaction = transaction; _type = State(initialValue: transaction.type); _amount = State(initialValue: "\(transaction.amount)"); _date = State(initialValue: transaction.date); _note = State(initialValue: transaction.note); _ledger = State(initialValue: transaction.ledger); _category = State(initialValue: transaction.category); _source = State(initialValue: transaction.sourceAccount); _destination = State(initialValue: transaction.destinationAccount); _reimbursable = State(initialValue: transaction.isReimbursable) }
    var body: some View { NavigationStack { Form { Picker("类型", selection: $type) { ForEach(TransactionType.allCases) { Text($0.title).tag($0) } }.pickerStyle(.segmented); Section("金额与时间") { TextField("金额", text: $amount).keyboardType(.decimalPad); DatePicker("时间", selection: $date) }; Section("归属") { Picker("账本", selection: $ledger) { ForEach(ledgers) { Text($0.name).tag(Optional($0)) } }; if type != .transfer { Picker("分类", selection: $category) { ForEach(categories.filter { $0.type == (type == .income ? .income : .expense) }) { Text($0.name).tag(Optional($0)) } } }; if type != .income { Picker("转出账户", selection: $source) { ForEach(accounts) { Text($0.name).tag(Optional($0)) } } }; if type != .expense { Picker("转入账户", selection: $destination) { ForEach(accounts) { Text($0.name).tag(Optional($0)) } } } }; Section("补充信息") { TextField("备注", text: $note); Toggle("标记报销", isOn: $reimbursable) } }.navigationTitle("编辑交易").toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("保存") { save() } } }.alert("无法保存", isPresented: .constant(errorMessage != nil)) { Button("好") { errorMessage = nil } } message: { Text(errorMessage ?? "") } } }
    private func save() { guard let value = Decimal(string: amount) else { errorMessage = "请输入有效金额"; return }; let draft = TransactionService.Draft(type: type, amount: value, date: date, note: note, currency: ledger?.currency ?? transaction.currency, tags: transaction.tags, isReimbursable: reimbursable, receiptData: transaction.receiptData, ledger: ledger, category: category, source: type == .income ? nil : source, destination: type == .expense ? nil : destination); do { try TransactionService.update(transaction, with: draft, in: context); dismiss() } catch { errorMessage = error.localizedDescription } }
}

struct CashflowCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    let transactions: [FinanceTransaction]; @State var month: Date
    var body: some View { NavigationStack { List { MonthSelector(date: $month); ForEach(daysWithTransactions, id: \.self) { day in NavigationLink { List(transactions.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }) { TransactionRow(transaction: $0) }.navigationTitle(day.formatted(DateFormats.shortDay)) } label: { HStack { Text(day, format: DateFormats.day); Spacer(); VStack(alignment: .trailing) { Text("支 " + CurrencyFormatter.string(total(day, .expense))).foregroundStyle(.red); Text("收 " + CurrencyFormatter.string(total(day, .income))).foregroundStyle(.green) }.font(.caption) } } } }.navigationTitle("收支日历").toolbar { Button("完成") { dismiss() } } } }
    private var daysWithTransactions: [Date] { Array(Set(transactions.map { Calendar.current.startOfDay(for: $0.date) })).sorted() }
    private func total(_ day: Date, _ type: TransactionType) -> Decimal { FinanceCalculator.total(transactions.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }, type: type) }
}

struct TransactionSearchView: View {
    @Query(sort: \FinanceTransaction.date, order: .reverse) private var transactions: [FinanceTransaction]
    @State private var query = ""; @State private var type: TransactionType?
    var body: some View { List { Picker("类型", selection: $type) { Text("全部").tag(nil as TransactionType?); ForEach(TransactionType.allCases) { Text($0.title).tag(Optional($0)) } }.pickerStyle(.segmented); if results.isEmpty { ContentUnavailableView.search(text: query) } else { ForEach(results) { NavigationLink { TransactionDetailView(transaction: $0) } label: { TransactionRow(transaction: $0) } } } }.navigationTitle("搜索").searchable(text: $query, prompt: "金额、备注、分类、账户、标签") }
    private var results: [FinanceTransaction] { transactions.filter { item in let matchesType = type == nil || item.type == type; let haystack = ["\(item.amount)", item.note, item.category?.name ?? "", item.sourceAccount?.name ?? "", item.destinationAccount?.name ?? "", item.tagsText].joined(separator: " "); return matchesType && (query.isEmpty || haystack.localizedStandardContains(query)) } }
}
