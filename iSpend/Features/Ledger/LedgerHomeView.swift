import SwiftUI
import SwiftData

private enum LedgerSheet: Identifiable { case add, calendar, customRange; var id: Self { self } }

private enum LedgerRange: String, CaseIterable, Identifiable {
    case week, month, year, custom
    var id: Self { self }
    var title: String { switch self { case .week: "周"; case .month: "月"; case .year: "年"; case .custom: "范围" } }
    var component: Calendar.Component { switch self { case .week: .weekOfYear; case .month: .month; case .year: .year; case .custom: .day } }
}

private enum LedgerDataFilter: String, CaseIterable, Identifiable {
    case expense, income, cashflow, all
    var id: Self { self }
    var title: String { switch self { case .expense: "仅支出"; case .income: "仅收入"; case .cashflow: "显示收支"; case .all: "全部" } }
}

struct LedgerHomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FinanceTransaction.date, order: .reverse) private var allTransactions: [FinanceTransaction]
    @Query(sort: \Ledger.createdAt) private var ledgers: [Ledger]
    @State private var selectedLedgerID: UUID?
    @State private var anchorDate = Date.now
    @State private var range = LedgerRange.month
    @State private var dataFilter = LedgerDataFilter.all
    @State private var customStart = Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now
    @State private var customEnd = Date.now
    @State private var sheet: LedgerSheet?
    @State private var selectedTransaction: FinanceTransaction?
    @State private var deleteTarget: FinanceTransaction?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ledgerContent
        }
    }

    private var ledgerContent: some View {
        ledgerList
            .listStyle(.insetGrouped)
            .navigationTitle("账单")
            .toolbar { ledgerToolbar }
            .overlay(alignment: .bottomTrailing) { addButton }
            .sheet(item: $sheet, content: sheetContent)
            .sheet(item: $selectedTransaction) { TransactionEditorView(transaction: $0) }
            .confirmationDialog("删除这笔交易？", isPresented: deletePresented, titleVisibility: .visible) {
                Button("删除", role: .destructive, action: deleteSelected)
                Button("取消", role: .cancel) { deleteTarget = nil }
            } message: {
                Text("账户余额将自动恢复。")
            }
            .alert("操作失败", isPresented: errorPresented) { } message: {
                Text(errorMessage ?? "未知错误")
            }
            .onChange(of: range) {
                if range == .custom { sheet = .customRange }
            }
    }

    private var ledgerList: some View {
        List {
            filterSection
            Section {
                SummaryCard(
                    expense: periodExpense,
                    income: periodIncome,
                    currency: currentLedger?.currency ?? "CNY"
                )
                .listRowInsets(.init())
                .listRowBackground(Color.clear)
            }
            if transactions.isEmpty { emptyState }
            transactionSections
        }
    }

    private var filterSection: some View {
        Section("查看范围") {
            ledgerPicker
            Picker("时间范围", selection: $range) {
                ForEach(LedgerRange.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            periodSelector
            Picker("数据类型", selection: $dataFilter) {
                ForEach(LedgerDataFilter.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.menu)
            Button("收支日历", systemImage: "calendar") { sheet = .calendar }
        }
    }

    @ViewBuilder private var emptyState: some View {
        ContentUnavailableView(
            "没有符合条件的账单",
            systemImage: "line.3.horizontal.decrease.circle",
            description: Text("可调整时间范围或数据类型筛选")
        )
        Button("开始记账") { sheet = .add }
            .frame(maxWidth: .infinity)
    }

    private var transactionSections: some View {
        ForEach(groupedDates, id: \.self) { day in
            Section {
                ForEach(transactionsForDay(day)) { item in
                    transactionLink(item)
                }
            } header: {
                DayHeader(day: day, transactions: transactions)
            }
        }
    }

    private func transactionsForDay(_ day: Date) -> [FinanceTransaction] {
        transactions.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    private func transactionLink(_ item: FinanceTransaction) -> some View {
        NavigationLink {
            TransactionDetailView(transaction: item)
        } label: {
            TransactionRow(transaction: item)
        }
        .swipeActions(edge: .trailing) {
            Button("删除", systemImage: "trash", role: .destructive) { deleteTarget = item }
            Button("编辑", systemImage: "pencil") { selectedTransaction = item }
                .tint(.orange)
        }
        .contextMenu {
            Button("复制交易", systemImage: "doc.on.doc") { duplicate(item) }
            Button(item.isReimbursable ? "取消报销标记" : "标记报销", systemImage: "doc.text") {
                item.isReimbursable.toggle()
                saveContext()
            }
        }
    }

    @ToolbarContentBuilder private var ledgerToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                FeatureMenuView()
            } label: {
                Label("更多功能", systemImage: "ellipsis.circle")
            }
                .labelStyle(.iconOnly)
        }
    }

    private var addButton: some View {
        Button("新增交易", systemImage: "plus") { sheet = .add }
            .labelStyle(.iconOnly)
            .font(.title2.bold())
            .foregroundStyle(.white)
            .frame(width: 58, height: 58)
            .background(.tint, in: Circle())
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .padding(20)
    }

    @ViewBuilder private func sheetContent(_ destination: LedgerSheet) -> some View {
        switch destination {
        case .add:
            QuickEntryView(preselectedLedger: currentLedger)
        case .calendar:
            CashflowCalendarView(transactions: periodTransactions, month: anchorDate)
        case .customRange:
            CustomDateRangeView(start: $customStart, end: $customEnd)
        }
    }

    private var currentLedger: Ledger? { ledgers.first { $0.id == selectedLedgerID } ?? ledgers.first }
    private var selectedInterval: DateInterval? {
        if range == .custom {
            let start = Calendar.current.startOfDay(for: min(customStart, customEnd))
            let last = Calendar.current.startOfDay(for: max(customStart, customEnd))
            return Calendar.current.date(byAdding: .day, value: 1, to: last).map { DateInterval(start: start, end: $0) }
        }
        return Calendar.current.dateInterval(of: range.component, for: anchorDate)
    }
    private var ledgerTransactions: [FinanceTransaction] { allTransactions.filter { currentLedger == nil || $0.ledger?.id == currentLedger?.id } }
    private var periodTransactions: [FinanceTransaction] { ledgerTransactions.filter { selectedInterval?.contains($0.date) == true } }
    private var transactions: [FinanceTransaction] {
        periodTransactions.filter { item in switch dataFilter { case .expense: item.type == .expense; case .income: item.type == .income; case .cashflow: item.type != .transfer; case .all: true } }
    }
    private var periodExpense: Decimal { FinanceCalculator.total(periodTransactions, type: .expense) }
    private var periodIncome: Decimal { FinanceCalculator.total(periodTransactions, type: .income) }
    private var groupedDates: [Date] { Array(Set(transactions.map { Calendar.current.startOfDay(for: $0.date) })).sorted(by: >) }
    private var deletePresented: Binding<Bool> { Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }) }
    private var errorPresented: Binding<Bool> { Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }) }
    private var ledgerPicker: some View { Picker("账本", selection: Binding(get: { currentLedger?.id }, set: { selectedLedgerID = $0 })) { ForEach(ledgers) { Label($0.name, systemImage: $0.symbolName).tag(Optional($0.id)) } }.pickerStyle(.menu) }
    private var periodSelector: some View {
        HStack {
            if range != .custom { Button("上一个周期", systemImage: "chevron.left") { shift(-1) }.labelStyle(.iconOnly) }
            Spacer(); Button(rangeTitle) { if range == .custom { sheet = .customRange } }.font(.headline)
            Spacer(); if range != .custom { Button("下一个周期", systemImage: "chevron.right") { shift(1) }.labelStyle(.iconOnly) }
        }
    }
    private var rangeTitle: String {
        if range == .custom { return "\(customStart.formatted(DateFormats.shortDay)) – \(customEnd.formatted(DateFormats.shortDay))" }
        guard let interval = selectedInterval else { return "选择时间" }
        switch range { case .week: return "\(interval.start.formatted(DateFormats.shortDay)) – \(interval.end.addingTimeInterval(-1).formatted(DateFormats.shortDay))"; case .month: return anchorDate.formatted(DateFormats.month); case .year: return anchorDate.formatted(.dateTime.year()); case .custom: return "选择时间" }
    }
    private func shift(_ amount: Int) { anchorDate = Calendar.current.date(byAdding: range.component, value: amount, to: anchorDate) ?? anchorDate }
    private func duplicate(_ item: FinanceTransaction) { let draft = TransactionService.Draft(type: item.type, amount: item.amount, date: .now, note: item.note, currency: item.currency, tags: item.tags, isReimbursable: item.isReimbursable, receiptData: item.receiptData, ledger: item.ledger, category: item.category, source: item.sourceAccount, destination: item.destinationAccount); do { _ = try TransactionService.create(draft, in: context) } catch { errorMessage = error.localizedDescription } }
    private func deleteSelected() { guard let item = deleteTarget else { return }; do { try TransactionService.delete(item, in: context) } catch { errorMessage = error.localizedDescription }; deleteTarget = nil }
    private func saveContext() { do { try context.save() } catch { errorMessage = error.localizedDescription } }
}

private struct CustomDateRangeView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var start: Date
    @Binding var end: Date
    var body: some View { NavigationStack { Form { DatePicker("开始日期", selection: $start, displayedComponents: .date); DatePicker("结束日期", selection: $end, displayedComponents: .date) }.navigationTitle("自定义时间范围").toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } } }.presentationDetents([.medium]) }
}

private struct DayHeader: View {
    let day: Date; let transactions: [FinanceTransaction]
    var body: some View { HStack { Text(day, format: DateFormats.day); Spacer(); let daily = transactions.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }; Text("支出 " + CurrencyFormatter.string(FinanceCalculator.total(daily, type: .expense))).font(.caption) } }
}
