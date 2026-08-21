import SwiftUI
import SwiftData

struct LedgerManagementView: View {
    @Query(sort: \Ledger.createdAt) private var ledgers: [Ledger]
    @State private var editing: Ledger?
    @State private var adding = false

    var body: some View {
        List {
            ForEach(ledgers) { ledger in
                Button { editing = ledger } label: {
                    HStack {
                        Image(systemName: ledger.symbolName).foregroundStyle(Color(hex: ledger.colorHex))
                        VStack(alignment: .leading) { Text(ledger.name).foregroundStyle(.primary); Text(ledger.currency).font(.caption).foregroundStyle(.secondary) }
                        Spacer(); Text("\(ledger.transactions.count) 笔").foregroundStyle(.secondary)
                    }
                }.disabled(ledger.name == "默认账本")
            }
        }
        .navigationTitle("账本管理")
        .toolbar { Button("新增账本", systemImage: "plus") { adding = true } }
        .sheet(isPresented: $adding) { LedgerEditorView() }
        .sheet(item: $editing) { LedgerEditorView(ledger: $0) }
    }
}

struct LedgerEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var ledger: Ledger?
    @State private var name: String
    @State private var symbol: String
    @State private var currency: String
    @State private var errorMessage: String?

    init(ledger: Ledger? = nil) {
        self.ledger = ledger
        _name = State(initialValue: ledger?.name ?? "")
        _symbol = State(initialValue: ledger?.symbolName ?? "book.closed")
        _currency = State(initialValue: ledger?.currency ?? "CNY")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("名称", text: $name)
                TextField("SF Symbol", text: $symbol)
                Picker("默认币种", selection: $currency) { ForEach(["CNY", "USD", "EUR", "JPY"], id: \.self) { Text($0) } }
            }
            .navigationTitle(ledger == nil ? "新增账本" : "编辑账本")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存", action: save).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
            .alert("无法保存", isPresented: errorPresented) { } message: { Text(errorMessage ?? "") }
        }
    }

    private var errorPresented: Binding<Bool> { Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }) }
    private func save() {
        let model = ledger ?? Ledger(name: name)
        model.name = name.trimmingCharacters(in: .whitespacesAndNewlines); model.symbolName = symbol; model.currency = currency
        if ledger == nil { context.insert(model) }
        do { try context.save(); dismiss() } catch { errorMessage = error.localizedDescription }
    }
}

struct CategoryManagementView: View {
    @Query(sort: \FinanceCategory.sortOrder) private var categories: [FinanceCategory]
    @State private var type = CategoryType.expense
    @State private var editing: FinanceCategory?
    @State private var adding = false

    private var roots: [FinanceCategory] { categories.filter { $0.type == type && !$0.isSubcategory } }

    var body: some View {
        List {
            Picker("分类类型", selection: $type) { Text("支出").tag(CategoryType.expense); Text("收入").tag(CategoryType.income) }.pickerStyle(.segmented)
            ForEach(roots) { root in
                Section {
                    Button { editing = root } label: { categoryRow(root) }
                    ForEach(categories.filter { $0.type == type && $0.parentName == root.name }) { child in
                        Button { editing = child } label: { categoryRow(child).padding(.leading, 26) }
                    }
                } header: { Text(root.displayName) }
            }
        }
        .navigationTitle("分类管理")
        .toolbar { Button("新增分类", systemImage: "plus") { adding = true } }
        .sheet(isPresented: $adding) { CategoryEditorView(type: type, availableParents: roots) }
        .sheet(item: $editing) { CategoryEditorView(category: $0, type: $0.type, availableParents: roots) }
    }

    private func categoryRow(_ category: FinanceCategory) -> some View {
        HStack {
            CategoryIcon(category: category)
            VStack(alignment: .leading) { Text(category.displayName).foregroundStyle(category.isEnabled ? .primary : .secondary); if category.isSubcategory { Text("二级分类").font(.caption).foregroundStyle(.secondary) } }
            Spacer(); if !category.isEnabled { Text("已隐藏").font(.caption).foregroundStyle(.secondary) }
        }
    }
}

struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var category: FinanceCategory?
    let type: CategoryType
    let availableParents: [FinanceCategory]
    @State private var name: String
    @State private var symbol: String
    @State private var parentName: String?
    @State private var enabled: Bool
    @State private var errorMessage: String?

    init(category: FinanceCategory? = nil, type: CategoryType, availableParents: [FinanceCategory] = []) {
        self.category = category; self.type = type; self.availableParents = availableParents
        _name = State(initialValue: category?.displayName ?? "")
        _symbol = State(initialValue: category?.symbolName ?? "tag")
        _parentName = State(initialValue: category?.parentName)
        _enabled = State(initialValue: category?.isEnabled ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("分类信息") {
                    HStack { CategoryIcon(category: category); TextField("分类名称", text: $name) }
                    TextField("SF Symbol", text: $symbol)
                    Picker("上级分类", selection: $parentName) {
                        Text("无（一级分类）").tag(nil as String?)
                        ForEach(availableParents.filter { $0.id != category?.id }) { parent in Text(parent.displayName).tag(Optional(parent.name)) }
                    }
                    Toggle("启用分类", isOn: $enabled)
                }
                if category?.transactions.isEmpty == false { Section { Text("已有交易使用此分类，因此只能隐藏，不能直接删除。").font(.footnote).foregroundStyle(.secondary) } }
            }
            .navigationTitle(category == nil ? "新增分类" : "编辑分类")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存", action: save).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
            .alert("无法保存", isPresented: errorPresented) { } message: { Text(errorMessage ?? "") }
        }
    }

    private var errorPresented: Binding<Bool> { Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }) }
    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines).replacing("/", with: "-")
        let storedName = FinanceCategory.storageName(cleanName, parentName: parentName)
        let model = category ?? FinanceCategory(name: storedName, symbolName: symbol, colorHex: "#007AFF", type: type)
        model.name = storedName; model.symbolName = symbol; model.isEnabled = enabled
        if category == nil { context.insert(model) }
        do { try context.save(); dismiss() } catch { errorMessage = error.localizedDescription }
    }
}
