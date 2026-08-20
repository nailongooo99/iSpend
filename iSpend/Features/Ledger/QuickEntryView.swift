import SwiftUI
import SwiftData
import PhotosUI

struct QuickEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Ledger.createdAt) private var ledgers: [Ledger]
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query(sort: \FinanceCategory.sortOrder) private var categories: [FinanceCategory]
    let preselectedLedger: Ledger?
    @State private var type = TransactionType.expense
    @State private var expression = ""
    @State private var selectedCategory: FinanceCategory?
    @State private var ledger: Ledger?
    @State private var source: Account?
    @State private var destination: Account?
    @State private var note = ""
    @State private var date = Date.now
    @State private var reimbursable = false
    @State private var photoItem: PhotosPickerItem?
    @State private var receiptData: Data?
    @State private var errorMessage: String?
    @State private var savedPulse = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Picker("交易类型", selection: $type) { ForEach(TransactionType.allCases) { Text($0.title).tag($0) } }.pickerStyle(.segmented).onChange(of: type) { selectedCategory = nil }
                    if type == .transfer { transferAccounts } else { categoryGrid }
                    quickTags
                    VStack(spacing: 10) { Text(displayAmount).font(.system(.largeTitle, design: .rounded, weight: .bold)).monospacedDigit().foregroundStyle(type == .income ? .green : type == .transfer ? .blue : selectedCategory.map { Color(hex: $0.colorHex) } ?? .primary); HStack { DatePicker("时间", selection: $date).labelsHidden(); TextField("点击填写备注", text: $note).multilineTextAlignment(.trailing) } }.padding().background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
                    FinancialKeypad(expression: $expression, onSaveAgain: { save(close: false) }, onDone: { save(close: true) })
                }.padding()
            }
            .navigationTitle("快速记账").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }; ToolbarItem(placement: .topBarTrailing) { Picker("账本", selection: $ledger) { ForEach(ledgers) { Text($0.name).tag(Optional($0)) } }.pickerStyle(.menu) } }
            .onAppear { ledger = preselectedLedger ?? ledgers.first; source = accounts.first; destination = accounts.dropFirst().first ?? accounts.first }
            .onChange(of: photoItem) { _, item in guard let item else { return }; Task { receiptData = try? await item.loadTransferable(type: Data.self) } }
            .sensoryFeedback(.success, trigger: savedPulse)
            .alert("无法保存", isPresented: .constant(errorMessage != nil)) { Button("好") { errorMessage = nil } } message: { Text(errorMessage ?? "未知错误") }
        }.presentationDetents([.large])
    }
    private var availableCategories: [FinanceCategory] { categories.filter { $0.isEnabled && $0.type == (type == .income ? .income : .expense) } }
    private var categoryGrid: some View { LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) { ForEach(availableCategories) { category in Button { selectedCategory = category } label: { VStack(spacing: 6) { CategoryIcon(category: category, size: 44).overlay { if selectedCategory?.id == category.id { Circle().stroke(Color(hex: category.colorHex), lineWidth: 2) } }; Text(category.name).font(.caption2).foregroundStyle(.primary).lineLimit(1) } }.buttonStyle(.plain).accessibilityLabel("分类：\(category.name)") } } }
    private var transferAccounts: some View { VStack { Picker("转出账户", selection: $source) { ForEach(accounts) { Text($0.name).tag(Optional($0)) } }; Picker("转入账户", selection: $destination) { ForEach(accounts) { Text($0.name).tag(Optional($0)) } } }.pickerStyle(.menu).padding().background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16)) }
    private var quickTags: some View { ScrollView(.horizontal) { HStack { Menu { ForEach(accounts) { account in Button(account.name) { if type == .income { destination = account } else { source = account } } } } label: { Label((type == .income ? destination : source)?.name ?? "账户", systemImage: "wallet.bifold") }; Button { reimbursable.toggle() } label: { Label("报销", systemImage: reimbursable ? "checkmark.circle.fill" : "circle") }; PhotosPicker("图片", selection: $photoItem, matching: .images).accessibilityLabel(receiptData == nil ? "添加账单图片" : "更换账单图片") }.buttonStyle(.bordered) }.scrollIndicators(.hidden) }
    private var displayAmount: String { CurrencyFormatter.string(KeypadCalculator.evaluate(expression) ?? 0, currency: ledger?.currency ?? "CNY") }
    private func save(close: Bool) { guard let amount = KeypadCalculator.evaluate(expression) else { errorMessage = "请输入有效金额"; return }; let draft = TransactionService.Draft(type: type, amount: amount, date: date, note: note, currency: ledger?.currency ?? "CNY", tags: [], isReimbursable: reimbursable, receiptData: receiptData, ledger: ledger, category: selectedCategory, source: type == .income ? nil : source, destination: type == .expense ? nil : destination); do { _ = try TransactionService.create(draft, in: context); savedPulse += 1; if close { dismiss() } else { expression = ""; note = ""; receiptData = nil; reimbursable = false } } catch { errorMessage = error.localizedDescription } }
}

struct FinancialKeypad: View {
    @Binding var expression: String; let onSaveAgain: () -> Void; let onDone: () -> Void
    private let rows = [["1", "2", "3", "+"], ["4", "5", "6", "−"], ["7", "8", "9", "×"], [".", "0", "⌫", "÷"]]
    var body: some View { VStack(spacing: 10) { ForEach(rows, id: \.self) { row in HStack(spacing: 10) { ForEach(row, id: \.self) { key in Button { press(key) } label: { Text(key).font(.title2.weight(.medium)).frame(maxWidth: .infinity, minHeight: 52).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14)) }.buttonStyle(.plain).accessibilityLabel(key == "⌫" ? "删除" : key) } } }; HStack { Button("保存再记", action: onSaveAgain).buttonStyle(.bordered); Button("完成", action: onDone).buttonStyle(.borderedProminent).frame(maxWidth: .infinity) } }.sensoryFeedback(.selection, trigger: expression) }
    private func press(_ key: String) { if key == "⌫" { if !expression.isEmpty { expression.removeLast() } } else { expression.append(key) } }
}

enum KeypadCalculator {
    static func evaluate(_ expression: String) -> Decimal? {
        let normalized = expression.replacingOccurrences(of: "−", with: "-").replacingOccurrences(of: "×", with: "*").replacingOccurrences(of: "÷", with: "/")
        guard !normalized.isEmpty else { return nil }
        var values: [Decimal] = []; var operators: [Character] = []; var token = ""
        func precedence(_ op: Character) -> Int { op == "+" || op == "-" ? 1 : 2 }
        func apply() -> Bool { guard let op = operators.popLast(), let right = values.popLast(), let left = values.popLast() else { return false }; switch op { case "+": values.append(left + right); case "-": values.append(left - right); case "*": values.append(left * right); case "/": guard right != 0 else { return false }; values.append(left / right); default: return false }; return true }
        for character in normalized { if character.isNumber || character == "." { token.append(character) } else { guard let number = Decimal(string: token) else { return nil }; values.append(number); token = ""; while let last = operators.last, precedence(last) >= precedence(character) { guard apply() else { return nil } }; operators.append(character) } }
        guard let number = Decimal(string: token) else { return nil }; values.append(number)
        while !operators.isEmpty { guard apply() else { return nil } }
        guard let result = values.first, values.count == 1, result > 0 else { return nil }; return result
    }
}
