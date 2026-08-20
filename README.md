# iSpend

“我花，我掌控” — a native Swift 6 + SwiftUI personal finance app.

## Requirements

- Xcode 16.0+ / iOS 18+
- Swift 6, SwiftUI, SwiftData, Charts

## Build an unsigned IPA on GitHub

Push this repository to GitHub and run **Actions → Build unsigned IPA**. The workflow uses a hosted macOS runner, builds an iOS Release archive without a signing identity, creates an unsigned `.app`, packages it as an `.ipa`, and uploads it as an artifact. An unsigned IPA cannot be installed directly on a normal iPhone; it is intended for later signing or inspection.

## Scope

The current product slice is a functional MVP: ledger, transactions, expense/income/transfer entry, account balance reconciliation, budgets, charts, search, edit/delete, dark mode, and local SwiftData persistence. The data model also includes savings, recurring payment, and installment foundations for the next product slice.
