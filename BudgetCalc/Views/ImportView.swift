import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]

    @State private var bankName = ""
    @State private var isPickerPresented = false
    @State private var parsed: [ParsedTransaction] = []
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var importedCount = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    importCard

                    if !parsed.isEmpty {
                        previewCard
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

            TextField("Bank name (e.g. AMEX, ECU)", text: $bankName)
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
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Preview")
                        .font(.headline)
                    Text("\(parsed.count) transactions found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Import All") {
                    saveTransactions()
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            ForEach(parsed.prefix(8)) { t in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.description)
                            .lineLimit(1)
                            .font(.subheadline)
                        Text(t.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(t.amount, format: .currency(code: "USD"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(t.amount >= 0 ? .green : .primary)
                }
            }

            if parsed.count > 8 {
                Text("+ \(parsed.count - 8) more transactions…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                parsed = []
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

            let results = PDFParser.extractTransactions(from: url)
            if results.isEmpty {
                errorMessage = "No transactions could be found in this PDF.\n\nMake sure the file is a text-based bank statement (not a scanned image)."
            } else {
                parsed = results
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func saveTransactions() {
        seedCategoriesIfNeeded()

        let bank = bankName.trimmingCharacters(in: .whitespaces)
        for p in parsed {
            let t = Transaction(
                date: p.date,
                transactionDescription: p.description,
                amount: p.amount,
                bankName: bank
            )
            modelContext.insert(t)
        }

        importedCount = parsed.count
        parsed = []
        showSuccess = true
    }

    private func seedCategoriesIfNeeded() {
        guard categories.isEmpty else { return }
        for (name, colorHex, icon) in DefaultCategories.all {
            modelContext.insert(Category(name: name, colorHex: colorHex, icon: icon))
        }
    }
}
