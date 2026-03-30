import SwiftUI
import SwiftData

struct CategoryDetailsView: View {
    let month: Date
    let account: String
    let category: String
    
    @Query(sort: \Transaction.date, order: .forward) private var allTransactions: [Transaction]
    
    private let calendar = Calendar.current
    
    private var total: Double { filtered.reduce(0) { $0 + $1.absoluteAmount } }
    private var count: Int { filtered.count }
    private var avg: Double { count > 0 ? total / Double(count) : 0 }
    
    @State private var selectedTransaction: Transaction?

    private var filtered: [Transaction] {
        allTransactions.filter {
            calendar.isDate($0.date, equalTo: month, toGranularity: .month) &&
            (account == "All Accounts" || $0.accountName == account) &&
            (category == "Uncategorized" ? $0.category == nil :
            category == "Income" ? ($0.category?.name == "Income" || ($0.category == nil && $0.isIncome)) :
            $0.category?.name == category || category == "All Categories") // "All Categories" is not necessarily needed
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        List {
            Section {
                // Summary header (total, count, average)
                HStack {
                    Text("Total")
                    Spacer()
                    Text(total, format: .currency(code: "USD"))
                }
                HStack {
                    Text("Transactions")
                    Spacer()
                    Text("\(count)")
                }
                HStack {
                    Text("Average")
                    Spacer()
                    Text(avg, format: .currency(code: "USD"))
                }
            }
            
            Section {
                // ForEach filtered transactions using CategoryTransactionRow
                ForEach(filtered) { transaction in
                    CategoryTransactionRow(transaction: transaction)
                        .onTapGesture { selectedTransaction = transaction }
                }
            }
        }
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedTransaction) { t in
            CategoryPickerView(transaction: t)
        }
    }
}

struct CategoryTransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Category icon badge
            ZStack {
                Circle()
                    .fill(transaction.category?.color.opacity(0.15) ?? Color(.systemGray5))
                    .frame(width: 36, height: 36)
                Image(systemName: transaction.category?.icon ?? "questionmark")
                    .foregroundStyle(transaction.category?.color ?? Color(.systemGray))
                    .imageScale(.small)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.transactionDescription)
                    .lineLimit(1)
                    .font(.subheadline)
                HStack(spacing: 4) {
                    Text(transaction.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !transaction.accountName.isEmpty {
                        Text("· \(transaction.accountName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let cat = transaction.category {
                        Text("· \(cat.name)")
                            .font(.caption)
                            .foregroundStyle(cat.color)
                    } else {
                        Text("· Uncategorized")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            Text(transaction.amount, format: .currency(code: "USD"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transaction.isIncome ? .green : .primary)
        }
        .padding(.vertical, 2)
    }
}

