import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    @Binding var selectedTab: Int
    @Binding var selectedBank: String
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    
    @State private var selectedAccount = "All Accounts"
    @State private var monthRange: Int = 3
    
    private let options = [3, 6, 12]
    private let calendar = Calendar.current
    
    private var availableBanks: [String] {
        let names = Set(transactions.map(\.bankName)).filter { !$0.isEmpty }
        return ["All Banks"] + names.sorted()
    }

    private var availableAccounts: [String] {
        let names = Set(transactions
            .filter { selectedBank == "All Banks" || $0.bankName == selectedBank }
            .map(\.accountName))
            .filter { !$0.isEmpty }
        return ["All Accounts"] + names.sorted()
    }
    
    // MARK: - Data Computation
    
    private var monthlyData: [MonthData] {
        var result: [MonthData] = []
        for i in 0..<monthRange {
            let calculateDate: Int = monthRange - 1 - i
            let monthDate = calendar.date(byAdding: .month, value: -calculateDate, to: Date())!
            // Filter transactions
            let txForMonth = transactions.filter {
                calendar.isDate($0.date, equalTo: monthDate, toGranularity: .month) &&
                (selectedBank == "All Banks" || $0.bankName == selectedBank) &&
                (selectedAccount == "All Accounts" || $0.accountName == selectedAccount)
            }
            // Get the categories
            var map: [String: (Double, Color)] = [:]
            for t in txForMonth {
                guard t.isExpense else { continue }
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
            // Sum the income & expenses
            let income = txForMonth.filter(\.isIncome).reduce(0) { $0 + $1.amount }
            let expenses = txForMonth.filter(\.isExpense).reduce(0) { $0 + $1.absoluteAmount }
            // Append MonthData to result
            result.append(MonthData(month: monthDate, income: income, expenses: expenses, categories: map.map { ($0.key, $0.value.0, $0.value.1) }.sorted { $0.total > $1.total }))
        }
        return result
    }
    
    private var totalIncome: Double {
        monthlyData.reduce(0) { $0 + $1.income }
    }

    private var totalExpenses: Double {
        monthlyData.reduce(0) { $0 + $1.expenses }
    }
    
    private var categoryData: [CategoryTrend] {
        let allNames = Set(monthlyData.flatMap { $0.categories.map(\.name)})
        var result: [CategoryTrend] = []
        for name in allNames {
            let color = monthlyData.flatMap(\.categories).first(where: { $0.name == name })?.color ?? Color(.systemGray)
            let totals = monthlyData.map { month in
                month.categories.first(where: { $0.name == name })?.total ?? 0
            }
            result.append(CategoryTrend(name: name, color: color, monthlyTotals: totals))
        }
        return result.sorted { $0.monthlyTotals.reduce(0, +) > $1.monthlyTotals.reduce(0, +) }
    }
    
    // MARK: - Main body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Month Range", selection: $monthRange) {
                        ForEach(options, id: \.self) { months in
                            Text("\(months) mo").tag(months)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if availableAccounts.count > 1 && availableAccounts.count <= 4 {
                        Picker("Account", selection: $selectedAccount) {
                            ForEach(availableAccounts, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                    }


                    Chart(monthlyData, id: \.month) { item in
                        ForEach(item.categories, id: \.name) { category in
                            BarMark(
                                x: .value("Month", item.month, unit: .month),
                                y: .value("Amount", category.total)
                            )
                            .foregroundStyle(by: .value("Category", category.name))
                            .cornerRadius(4)
                        }
                    }
                    .frame(height: 180)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { value in
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                            AxisGridLine()
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel(format: .currency(code: "USD").precision(.fractionLength(0)))
                            AxisGridLine()
                        }
                    }
                    
                    summaryCards
                    categoryBreakdown
                }
                .padding()
                .navigationTitle("Trends")
                .toolbar {
                    if availableBanks.count > 1 {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Picker("Bank", selection: $selectedBank) {
                                    ForEach(availableBanks, id: \.self) { Text($0) }
                                }
                            } label: {
                                Label(selectedBank == "All Banks" ? "All Banks" : selectedBank,
                                      systemImage: "building.columns")
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(title: "Income",   value: totalIncome,   color: .green)
                SummaryCard(title: "Expenses", value: totalExpenses, color: .red)
            }
//            HStack(spacing: 12) {
//                SummaryCard(title: "Net", value: net, color: net >= 0 ? .green : .red)
//            }
        }
    }
    
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)
            
            ForEach(categoryData, id: \.name) { trend in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(trend.color)
                            .frame(width: 12, height: 12)
                        Text(trend.name)
                            .font(.subheadline.weight(.semibold))
                        if let pct = trend.trend {
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: pct >= 0 ? "arrow.up" : "arrow.down")
                                Text("\(abs(Int(pct)))%")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(pct >= 0 ? .red : .green)
                        }
                    }
                    
                    ForEach(Array(trend.monthlyTotals.enumerated()), id: \.offset) { index, total in
                        if total > 0 {
                            HStack {
                                Text(monthlyData[index].month, format: .dateTime.month(.wide))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(total, format: .currency(code: "USD"))
                                    .font(.caption.weight(.semibold))
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    
    // MARK: - Helpers
    
    struct MonthData {
        let month: Date
        let income: Double
        let expenses: Double
        let categories: [(name: String, total: Double, color: Color)]
    }
    
    struct CategoryTrend {
        let name: String
        let color: Color
        let monthlyTotals: [Double] // one entry per month, in order
        
        var trend: Double? {
            let nonZero = monthlyTotals.filter { $0 > 0 }
            guard nonZero.count >= 2 else { return nil }
            let previous = nonZero[nonZero.count - 2]
            let current = nonZero[nonZero.count - 1]
            return (current - previous) / previous * 100
        }
    }
}
