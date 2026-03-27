import SwiftUI
import SwiftData

struct TransactionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var searchText = ""
    @State private var selectedAccount = "All Accounts"
    @State private var selectedTransaction: Transaction?
    @State private var groupPendingDelete: (key: String, value: [Transaction])?

    private var availableAccounts: [String] {
        let names = Set(transactions.map(\.accountName)).filter { !$0.isEmpty }
        return ["All Accounts"] + names.sorted()
    }

    private var filtered: [Transaction] {
        transactions.filter { t in
            let matchesAccount = selectedAccount == "All Accounts" || t.accountName == selectedAccount
            let matchesSearch = searchText.isEmpty ||
                t.transactionDescription.localizedCaseInsensitiveContains(searchText) ||
                t.bankName.localizedCaseInsensitiveContains(searchText) ||
                (t.category?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            return matchesAccount && matchesSearch
        }
    }

    // Group by "Month Year" label, preserving sort order
    private var grouped: [(key: String, value: [Transaction])] {
        var order: [String] = []
        var map: [String: [Transaction]] = [:]
        for t in filtered {
            let label = t.date.formatted(.dateTime.month(.wide).year())
            if map[label] == nil { order.append(label) }
            map[label, default: []].append(t)
        }
        return order.map { ($0, map[$0]!) }
    }

    var body: some View {
        NavigationStack {
            List {
                if availableAccounts.count > 1 && availableAccounts.count <= 4 {
                    Section {
                        Picker("Account", selection: $selectedAccount) {
                            ForEach(availableAccounts, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                ForEach(grouped, id: \.key) { group in
                    Section {
                        ForEach(group.value) { transaction in
                            TransactionRow(transaction: transaction)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedTransaction = transaction }
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(group.value[i]) }
                        }
                    } header: {
                        HStack {
                            Text(group.key)
                            Spacer()
                            Button("Delete") {
                                groupPendingDelete = group
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search transactions")
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
            .sheet(item: $selectedTransaction) { t in
                CategoryPickerView(transaction: t)
            }
            .alert(
                "Delete \(groupPendingDelete?.key ?? "") Transactions?",
                isPresented: .constant(groupPendingDelete != nil)
            ) {
                Button("Delete", role: .destructive) {
                    if let group = groupPendingDelete {
                        for t in group.value { modelContext.delete(t) }
                    }
                    groupPendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    groupPendingDelete = nil
                }
            } message: {
                Text("This will permanently delete all \(groupPendingDelete?.value.count ?? 0) transactions for this month. This cannot be undone.")
            }
            .overlay {
                if transactions.isEmpty {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "creditcard",
                        description: Text("Import a bank statement to see your transactions.")
                    )
                }
            }
        }
    }
}

struct TransactionRow: View {
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
