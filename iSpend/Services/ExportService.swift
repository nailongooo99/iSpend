import Foundation

enum ExportService {
    static func csv(_ transactions: [FinanceTransaction]) -> Data {
        let header = "日期,类型,金额,币种,分类,账户,备注\n"
        let rows = transactions.map { item in
            let account = item.type == .income ? item.destinationAccount?.name : item.sourceAccount?.name
            return [item.date.formatted(.iso8601), item.type.title, "\(item.amount)", item.currency, item.category?.name ?? "转账", account ?? "", item.note].map(escape).joined(separator: ",")
        }.joined(separator: "\n")
        return Data((header + rows).utf8)
    }
    static func json(_ transactions: [FinanceTransaction]) -> Data {
        let values: [[String: String]] = transactions.map { ["id": $0.id.uuidString, "date": $0.date.formatted(.iso8601), "type": $0.type.rawValue, "amount": "\($0.amount)", "currency": $0.currency, "category": $0.category?.name ?? "", "note": $0.note] }
        return (try? JSONSerialization.data(withJSONObject: values, options: [.prettyPrinted, .sortedKeys])) ?? Data()
    }
    private static func escape(_ value: String) -> String { "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
}
