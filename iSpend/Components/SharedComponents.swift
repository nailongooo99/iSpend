import SwiftUI

struct AmountText: View {
    let amount: Decimal; var currency = "CNY"; var type: TransactionType?; var font: Font = .headline
    var body: some View { Text(CurrencyFormatter.string(amount, currency: currency, sign: type)).font(font).monospacedDigit().accessibilityLabel(CurrencyFormatter.string(amount, currency: currency, sign: type)) }
}

struct CategoryIcon: View {
    let category: FinanceCategory?; var size: CGFloat = 42
    var body: some View { Image(systemName: category?.symbolName ?? "arrow.left.arrow.right").font(.system(size: size * 0.42, weight: .medium)).foregroundStyle(category.map { Color(hex: $0.colorHex) } ?? .secondary).frame(width: size, height: size).background((category.map { Color(hex: $0.colorHex) } ?? .secondary).opacity(0.14), in: Circle()).accessibilityHidden(true) }
}

struct SummaryCard: View {
    let expense: Decimal; let income: Decimal; var currency = "CNY"
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("总支出").font(.subheadline).foregroundStyle(.secondary)
            AmountText(amount: expense, currency: currency, font: .largeTitle.bold())
            HStack { metric("总收入", income, .green); Spacer(); metric("结余", income - expense, .primary) }
        }.padding(20).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    private func metric(_ title: String, _ value: Decimal, _ color: Color) -> some View { VStack(alignment: .leading, spacing: 4) { Text(title).font(.caption).foregroundStyle(.secondary); AmountText(amount: value, currency: currency, font: .headline).foregroundStyle(color) } }
}

struct MonthSelector: View {
    @Binding var date: Date
    @State private var showingPicker = false
    var body: some View {
        HStack { Button("上个月", systemImage: "chevron.left") { shift(-1) }.labelStyle(.iconOnly); Spacer(); Button { showingPicker = true } label: { Text(date, format: DateFormats.month).font(.headline) }; Spacer(); Button("下个月", systemImage: "chevron.right") { shift(1) }.labelStyle(.iconOnly) }
            .sheet(isPresented: $showingPicker) { NavigationStack { DatePicker("选择月份", selection: $date, displayedComponents: .date).datePickerStyle(.graphical).padding().navigationTitle("选择月份").toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showingPicker = false } } } }.presentationDetents([.medium]) }
    }
    private func shift(_ value: Int) { withAnimation(.snappy) { date = Calendar.current.date(byAdding: .month, value: value, to: date) ?? date } }
}

struct TransactionRow: View {
    let transaction: FinanceTransaction
    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: transaction.category)
            VStack(alignment: .leading, spacing: 4) { Text(transaction.category?.displayName ?? "转账").font(.headline); if let parent = transaction.category?.parentName { Text(parent).font(.caption).foregroundStyle(.secondary) }; Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1); if transaction.isReimbursable { Label(transaction.isReimbursed ? "已报销" : "待报销", systemImage: "doc.text").font(.caption).foregroundStyle(.tint) } }
            Spacer(); VStack(alignment: .trailing, spacing: 4) { AmountText(amount: transaction.amount, currency: transaction.currency, type: transaction.type); Text(accountName).font(.caption).foregroundStyle(.secondary) }
        }.padding(.vertical, 4).accessibilityElement(children: .combine)
    }
    private var subtitle: String { transaction.date.formatted(DateFormats.time) + (transaction.note.isEmpty ? "" : " · " + transaction.note) }
    private var accountName: String { transaction.type == .income ? transaction.destinationAccount?.name ?? "" : transaction.sourceAccount?.name ?? "" }
}
