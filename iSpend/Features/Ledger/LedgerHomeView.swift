import SwiftUI
import SwiftData

private enum LedgerSheet: Identifiable { case add, calendar; var id: Self { self } }

struct LedgerHomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FinanceTransaction.date, order: .reverse) private var allTransactions: [FinanceTransaction]
    @Query(sort: \Ledger.createdAt) private var ledgers: [Ledger]
    @State private var selectedLedgerID: UUID?
    @State private var month = Date.now
    @State private var sheet: LedgerSheet?
    @State private var selectedTransaction: FinanceTransaction?
    @State private var deleteTarget: FinanceTransaction?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section { ledgerPicker; MonthSelector(date: $month); Button("收支日历", systemImage: "calendar") { sheet = .calendar } }
                Section { SummaryCard(expense: expense, income: income, currency: currentLedger?.currency ?? "CNY").listRowInsets(.init()).listRowBackground(Color.clear) }
                if transactions.isEmpty { ContentUnavailableView("还没有账单", systemImage: "tray", description: Text("点击 + 记录第一笔消费")); Button("开始记账") { sheet = .add }.frame(maxWidth: .infinity) }
                ForEach(groupedDates, id: \.self) { day in
                    Section { ForEach(transactions.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }) { item in
                        NavigationLink { TransactionDetailView(transaction: item) } label: { TransactionRow(transaction: item) }
                            .swipeActions(edge: .trailing) { Button("删除", systemImage: "trash", role: .destructive) { deleteTarget = item }; Button("编辑", systemImage: "pencil") { selectedTransaction = item }.tint(.orange) }
                            .contextMenu { Button("复制交易", systemImage: "doc.on.doc") { duplicate(item) }; Button(item.isReimbursable ? "取消报销标记" : "标记报销", systemImage: "doc.text") { item.isReimbursable.toggle(); try? context.save() } }
                    } } header: { DayHeader(day: day, transactions: transactions) }
                }
            }
            .listStyle(.insetGrouped).navigationTitle("账单")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { NavigationLink { FeatureMenuView() } label: { Image(systemName: "ellipsis.circle") }.accessibilityLabel("更多功能") } }
            .overlay(alignment: .bottomTrailing) { Button { sheet = .add } label: { Image(systemName: "plus").font(.title2.bold()).foregroundStyle(.white).frame(width: 58, height: 58).background(.tint, in: Circle()).shadow(color: .black.opacity(0.15), radius: 8, y: 4) }.padding(20).accessibilityLabel("新增交易") }
            .sheet(item: $sheet) { destination in switch destination { case .add: QuickEntryView(preselectedLedger: currentLedger); case .calendar: CashflowCalendarView(transactions: transactions, month: month) } }
            .sheet(item: $selectedTransaction) { TransactionEditorView(transaction: $0) }
            .confirmationDialog("删除这笔交易？", isPresented: .constant(deleteTarget != nil), titleVisibility: .visible) { Button("删除", role: .destructive) { if let item = deleteTarget { do { try TransactionService.delete(item, in: context) } catch { errorMessage = error.localizedDescription } }; deleteTarget = nil }; Button("取消", role: .cancel) { deleteTarget = nil } } message: { Text("账户余额将自动恢复。") }
            .alert("操作失败", isPresented: .constant(errorMessage != nil)) { Button("好") { errorMessage = nil } } message: { Text(errorMessage ?? "未知错误") }
        }
    }
    private var currentLedger: Ledger? { ledgers.first { $0.id == selectedLedgerID } ?? ledgers.first }
    private var transactions: [FinanceTransaction] { FinanceCalculator.transactions(allTransactions.filter { currentLedger == nil || $0.ledger?.id == currentLedger?.id }, in: month) }
    private var expense: Decimal { FinanceCalculator.total(transactions, type: .expense) }
    private var income: Decimal { FinanceCalculator.total(transactions, type: .income) }
    private var groupedDates: [Date] { Array(Set(transactions.map { Calendar.current.startOfDay(for: $0.date) })).sorted(by: >) }
    private var ledgerPicker: some View { Picker("账本", selection: Binding(get: { currentLedger?.id }, set: { selectedLedgerID = $0 })) { ForEach(ledgers) { Label($0.name, systemImage: $0.symbolName).tag(Optional($0.id)) } }.pickerStyle(.menu) }
    private func duplicate(_ item: FinanceTransaction) { let draft = TransactionService.Draft(type: item.type, amount: item.amount, date: .now, note: item.note, currency: item.currency, tags: item.tags, isReimbursable: item.isReimbursable, receiptData: item.receiptData, ledger: item.ledger, category: item.category, source: item.sourceAccount, destination: item.destinationAccount); do { _ = try TransactionService.create(draft, in: context) } catch { errorMessage = error.localizedDescription } }
}

private struct DayHeader: View {
    let day: Date; let transactions: [FinanceTransaction]
    var body: some View { HStack { Text(day, format: DateFormats.day); Spacer(); let daily = transactions.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }; Text("支出 " + CurrencyFormatter.string(FinanceCalculator.total(daily, type: .expense))).font(.caption) } }
}
