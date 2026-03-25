import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var selectedMonth = Date()
    @State private var selectedAccount = "All Accounts"
    private let calendar = Calendar.current

    private var availableAccounts: [String] {
        let names = Set(transactions.map(\.accountName)).filter { !$0.isEmpty }
        return ["All Accounts"] + names.sorted()
    }

    // MARK: - Computed

    private var monthTransactions: [Transaction] {
        transactions.filter {
            calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) &&
            (selectedAccount == "All Accounts" || $0.accountName == selectedAccount)
        }
    }

    private var totalIncome: Double {
        monthTransactions.filter(\.isIncome).reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        monthTransactions.filter(\.isExpense).reduce(0) { $0 + $1.absoluteAmount }
    }

    private var net: Double { totalIncome - totalExpenses }

    private var savingsRate: Double {
        guard totalIncome > 0 else { return 0 }
        return max(0, net / totalIncome * 100)
    }

    private var categoryBreakdown: [(name: String, total: Double, color: Color)] {
        var map: [String: (Double, Color)] = [:]
        for t in monthTransactions {
            let name: String
            let color: Color
            if let cat = t.category {
                name  = cat.name
                color = cat.color
            } else if t.isIncome {
                name  = "Income"
                color = .green
            } else {
                name  = "Uncategorized"
                color = Color(.systemGray)
            }
            map[name, default: (0, color)].0 += t.absoluteAmount
        }
        return map.map { ($0.key, $0.value.0, $0.value.1) }
                  .sorted { $0.total > $1.total }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthPicker
                    if availableAccounts.count > 1 && availableAccounts.count <= 4 {
                        Picker("Account", selection: $selectedAccount) {
                            ForEach(availableAccounts, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    summaryCards
                    if categoryBreakdown.isEmpty {
                        emptyState
                    } else {
                        spendingBreakdown
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                if availableAccounts.count > 2 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Account", selection: $selectedAccount) {
                                ForEach(availableAccounts, id: \.self) { Text($0) }
                            }
                        } label: {
                            Label(selectedAccount == "All Accounts" ? "All Accounts" : selectedAccount,
                                  systemImage: "building.columns")
                                .labelStyle(.titleAndIcon)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var monthPicker: some View {
        HStack {
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left").imageScale(.large)
            }
            Spacer()
            Text(selectedMonth, format: .dateTime.month(.wide).year())
                .font(.headline)
            Spacer()
            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right").imageScale(.large)
            }
        }
        .padding(.horizontal, 8)
    }

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(title: "Income",   value: totalIncome,   color: .green)
                SummaryCard(title: "Expenses", value: totalExpenses, color: .red)
            }
            HStack(spacing: 12) {
                SummaryCard(title: "Net", value: net, color: net >= 0 ? .green : .red)
                SavingsRateCard(rate: savingsRate)
            }
        }
    }

    private var spendingBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Breakdown by Category")
                .font(.headline)

            // Donut chart
            Chart(categoryBreakdown, id: \.name) { item in
                SectorMark(
                    angle: .value("Amount", item.total),
                    innerRadius: .ratio(0.55),
                    angularInset: 2
                )
                .foregroundStyle(item.color)
                .cornerRadius(4)
            }
            .frame(height: 220)

            // Legend
            VStack(spacing: 8) {
                ForEach(categoryBreakdown, id: \.name) { item in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(item.color)
                            .frame(width: 12, height: 12)
                        Text(item.name)
                        Spacer()
                        Text(item.total, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No data for this month")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Import a bank statement to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Helpers

    private func shiftMonth(_ value: Int) {
        selectedMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) ?? selectedMonth
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: "USD"))
                .font(.title3.bold())
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SavingsRateCard: View {
    let rate: Double

    private var color: Color {
        rate >= 20 ? .green : rate >= 10 ? .orange : .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Savings Rate")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(Int(rate))%")
                .font(.title3.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
