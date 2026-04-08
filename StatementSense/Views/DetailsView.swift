import SwiftUI
import SwiftData
import Charts

struct DetailsView: View {
    let month: Date
    let account: String

    @Query(sort: \Transaction.date, order: .forward) private var allTransactions: [Transaction]

    private let calendar = Calendar.current
    private let currencyFormat = FloatingPointFormatStyle<Double>.Currency(code: "USD")

    // MARK: - Filtered transactions

    private var transactions: [Transaction] {
        allTransactions.filter {
            calendar.isDate($0.date, equalTo: month, toGranularity: .month) &&
            (account == "All Accounts" || $0.accountName == account)
        }
    }

    private var expenses: [Transaction] {
        transactions.filter(\.isExpense)
    }

    // MARK: - Daily spending

    private var dailySpending: [(day: Int, total: Double)] {
        var map: [Int: Double] = [:]
        for t in expenses {
            let day = calendar.component(.day, from: t.date)
            map[day, default: 0] += t.absoluteAmount
        }
        return map.map { ($0.key, $0.value) }.sorted { $0.day < $1.day }
    }

    // MARK: - Top merchants

    private var topMerchants: [(name: String, total: Double)] {
        var map: [String: Double] = [:]
        for t in expenses {
            let name = cleanMerchantName(t.transactionDescription)
            map[name, default: 0] += t.absoluteAmount
        }
        let pairs: [(name: String, total: Double)] = map.map { (name: $0.key, total: $0.value) }
        return pairs.sorted { (a, b) in a.total > b.total }
                    .prefix(5)
                    .map { $0 }
    }

    // MARK: - Largest transactions

    private var largestTransactions: [Transaction] {
        let sorted = expenses.sorted { (a: Transaction, b: Transaction) -> Bool in
            a.absoluteAmount > b.absoluteAmount
        }
        return Array(sorted.prefix(5))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                dailyChart
                topMerchantsCard
                largestTransactionsCard
            }
            .padding()
        }
        .navigationTitle(month.formatted(.dateTime.month(.wide).year()))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Daily spending chart

    private var dailyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Spending")
                .font(.headline)

            if dailySpending.isEmpty {
                emptyCard(message: "No expense data for this month")
            } else {
                Chart(dailySpending, id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Amount", item.total)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 5)) { value in
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel(format: .currency(code: "USD").precision(.fractionLength(0)))
                        AxisGridLine()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Top merchants

    private var topMerchantsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Merchants")
                .font(.headline)

            if topMerchants.isEmpty {
                emptyCard(message: "No expense data for this month")
            } else {
                let maxTotal = topMerchants.first?.total ?? 1
                VStack(spacing: 10) {
                    ForEach(Array(topMerchants.enumerated()), id: \.offset) { index, merchant in
                        VStack(spacing: 4) {
                            HStack {
                                Text("\(index + 1).")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20, alignment: .leading)
                                Text(merchant.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer()
                                Text(merchant.total, format: currencyFormat)
                                    .font(.subheadline.bold())
                            }
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.accentColor.opacity(0.25))
                                    .frame(width: geo.size.width)
                                    .overlay(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.accentColor)
                                            .frame(width: geo.size.width * (merchant.total / maxTotal))
                                    }
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Largest transactions

    private var largestTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Largest Transactions")
                .font(.headline)

            if largestTransactions.isEmpty {
                emptyCard(message: "No expense data for this month")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(largestTransactions.enumerated()), id: \.element.id) { index, t in
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                // Category color dot
                                Circle()
                                    .fill(t.category?.color ?? Color(.systemGray3))
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cleanMerchantName(t.transactionDescription))
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Text(t.date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(t.absoluteAmount, format: currencyFormat)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.red)
                            }
                            .padding(.vertical, 10)

                            if index < largestTransactions.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func emptyCard(message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
    }

    /// Strips bank statement noise from merchant names for cleaner display.
    private func cleanMerchantName(_ raw: String) -> String {
        var name = raw
        // Remove common prefixes
        let prefixes = ["POS W/D ", "POS Deposit ", "Ext W/D ", "Ext Deposit ",
                        "W/D ", "Deposit ", "Descriptive Withdrawal "]
        for prefix in prefixes {
            if name.uppercased().hasPrefix(prefix.uppercased()) {
                name = String(name.dropFirst(prefix.count))
                break
            }
        }
        // Remove trailing state/country codes like "HERMITAGE TNUS" or "SEATTLE WAUS"
        name = name.replacingOccurrences(
            of: #"\s+[A-Z]{2,}\s*[A-Z]{2}US$"#,
            with: "",
            options: .regularExpression
        )
        // Truncate at # signs (store numbers)
        if let hashRange = name.range(of: " #") {
            name = String(name[..<hashRange.lowerBound])
        }
        return name.trimmingCharacters(in: .whitespaces).capitalized
    }
}
