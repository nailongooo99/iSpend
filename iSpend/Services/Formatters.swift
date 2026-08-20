import Foundation
import SwiftUI

enum CurrencyFormatter {
    static func string(_ amount: Decimal, currency: String = "CNY", sign: TransactionType? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: currency == "CNY" ? "zh_CN" : currency == "USD" ? "en_US" : currency == "EUR" ? "de_DE" : "ja_JP")
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = currency == "JPY" ? 0 : 2
        formatter.maximumFractionDigits = currency == "JPY" ? 0 : 2
        let base = formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
        switch sign { case .expense: return "−" + base; case .income: return "+" + base; default: return base }
    }
}

enum DateFormats {
    static let month = Date.FormatStyle(locale: Locale(identifier: "zh_CN")).year().month(.wide)
    static let day = Date.FormatStyle(locale: Locale(identifier: "zh_CN")).month().day().weekday(.wide)
    static let shortDay = Date.FormatStyle(locale: Locale(identifier: "zh_CN")).month(.defaultDigits).day(.defaultDigits)
    static let time = Date.FormatStyle(locale: Locale(identifier: "zh_CN")).hour().minute()
    static let full = Date.FormatStyle(locale: Locale(identifier: "zh_CN")).year().month().day().hour().minute()
}

extension Decimal {
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}

extension Color {
    init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var number: UInt64 = 0; Scanner(string: value).scanHexInt64(&number)
        let r, g, b: UInt64
        if value.count == 6 { (r, g, b) = (number >> 16, number >> 8 & 0xFF, number & 0xFF) } else { (r, g, b) = (0, 122, 255) }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
