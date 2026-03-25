import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]

    @State private var bankName = ""
    @State private var isPickerPresented = false
    @State private var parsedAccounts: [ParsedAccount] = []
    @State private var selectedAccounts: Set<String> = []
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var importedCount = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    importCard

                    if !parsedAccounts.isEmpty {
                        accountSelectionCard
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Import")
            .fileImporter(
                isPresented: $isPickerPresented,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("Could Not Parse PDF", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Import Complete", isPresented: $showSuccess) {
                Button("OK") {}
            } message: {
                Text("\(importedCount) transactions imported from \(bankName).")
            }
        }
    }

    // MARK: - Subviews

    private var importCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 52))
                .foregroundStyle(.tint)

            Text("Import Bank Statement")
                .font(.title3.bold())

            Text("Enter your bank name, then choose a PDF statement.\nTransactions will be extracted automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Bank name (e.g. AMEX, Chase, Citi, etc.)", text: $bankName)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()

            Button {
                isPickerPresented = true
            } label: {
                Label("Choose PDF", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(bankName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var accountSelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accounts Found")
                        .font(.headline)
                    Text("Select which accounts to import")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Import Selected") {
                    saveSelectedTransactions()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedAccounts.isEmpty)
            }

            Divider()

            ForEach(parsedAccounts) { account in
                AccountToggleRow(
                    account: account,
                    isSelected: selectedAccounts.contains(account.name)
                ) {
                    if selectedAccounts.contains(account.name) {
                        selectedAccounts.remove(account.name)
                    } else {
                        selectedAccounts.insert(account.name)
                    }
                }
            }

            Button(role: .destructive) {
                parsedAccounts = []
                selectedAccounts = []
            } label: {
                Label("Discard", systemImage: "trash")
                    .font(.subheadline)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Actions

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }

            let accounts = PDFParser.extractAccounts(from: url)
            if accounts.isEmpty {
                errorMessage = "No transactions could be found in this PDF.\n\nMake sure the file is a text-based bank statement (not a scanned image)."
            } else {
                parsedAccounts = accounts
                // Default: select all accounts
                selectedAccounts = Set(accounts.map(\.name))
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func saveSelectedTransactions() {
        seedCategoriesIfNeeded()

        // Reads the cateogries from seedCateogriesIfNeeded()
        let descriptor = FetchDescriptor<Category>()
        let fetchedCategories = (try? modelContext.fetch(descriptor)) ?? []
        let categoryMap = Dictionary(uniqueKeysWithValues: fetchedCategories.map { ($0.name, $0) })

        let bank = bankName.trimmingCharacters(in: .whitespaces)
        var count = 0

        for account in parsedAccounts where selectedAccounts.contains(account.name) {
            for p in account.transactions {
                let t = Transaction(
                    date: p.date,
                    transactionDescription: p.description,
                    amount: p.amount,
                    bankName: bank,
                    accountName: p.accountName
                )
                // Auto-categorize — user can still override later
                if let matchedName = AutoCategorizer.categorize(description: p.description, amount: p.amount),
                   let category = categoryMap[matchedName] {
                    t.category = category
                }
                modelContext.insert(t)
                count += 1
            }
        }

        importedCount = count
        parsedAccounts = []
        selectedAccounts = []
        showSuccess = true
    }

    private func seedCategoriesIfNeeded() {
        guard categories.isEmpty else { return }
        for (name, colorHex, icon) in DefaultCategories.all {
            modelContext.insert(Category(name: name, colorHex: colorHex, icon: icon))
        }
    }
}

// MARK: - Account Toggle Row

struct AccountToggleRow: View {
    let account: ParsedAccount
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color(.systemGray3))
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("\(account.transactions.count) transactions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Preview first/last date range
                if let first = account.transactions.map(\.date).min(),
                   let last  = account.transactions.map(\.date).max() {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(first, style: .date)
                        Text(last, style: .date)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
