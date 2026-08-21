import ActivityKit
import WidgetKit
import SwiftUI

struct SpendingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpendingActivityAttributes.self) { context in
            HStack(spacing: 14) {
                Image(systemName: "chart.pie.fill").font(.title2).foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.periodTitle).font(.caption).foregroundStyle(.secondary)
                    Text(context.state.metric.title).font(.headline)
                }
                Spacer()
                Text(context.state.preferredValue, format: .currency(code: context.attributes.currencyCode)).font(.title3.bold()).monospacedDigit()
            }.padding().activityBackgroundTint(.black.opacity(0.04)).activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Label(context.state.metric.title, systemImage: context.state.metric.symbolName).font(.headline) }
                DynamicIslandExpandedRegion(.trailing) { Text(context.state.preferredValue, format: .currency(code: context.attributes.currencyCode)).font(.headline).monospacedDigit() }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack { metric("支出", context.state.expense, .red, context.attributes.currencyCode); Spacer(); metric("收入", context.state.income, .green, context.attributes.currencyCode); Spacer(); metric("结余", context.state.balance, .primary, context.attributes.currencyCode) }.padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: context.state.metric.symbolName).foregroundStyle(.tint)
            } compactTrailing: {
                Text(context.state.preferredValue, format: .currency(code: context.attributes.currencyCode).precision(.fractionLength(0))).monospacedDigit()
            } minimal: {
                Image(systemName: "chart.pie.fill").foregroundStyle(.tint)
            }.keylineTint(.accentColor)
        }
    }

    private func metric(_ title: String, _ value: Double, _ color: Color, _ currency: String) -> some View {
        VStack(alignment: .leading, spacing: 2) { Text(title).font(.caption2).foregroundStyle(.secondary); Text(value, format: .currency(code: currency).precision(.fractionLength(0))).font(.caption.bold()).monospacedDigit().foregroundStyle(color) }
    }
}
