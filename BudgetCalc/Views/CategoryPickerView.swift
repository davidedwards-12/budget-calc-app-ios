import SwiftUI
import SwiftData

struct CategoryPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]

    let transaction: Transaction

    @State private var showingAddCategory = false
    @State private var newCategoryName = ""

    var body: some View {
        NavigationStack {
            List {
                // Transaction summary header
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.transactionDescription)
                            .font(.headline)
                            .lineLimit(2)
                        HStack {
                            Text(transaction.date, style: .date)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(transaction.amount, format: .currency(code: "USD"))
                                .fontWeight(.semibold)
                                .foregroundStyle(transaction.isIncome ? .green : .primary)
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }

                // Remove category
                if transaction.category != nil {
                    Section {
                        Button(role: .destructive) {
                            transaction.category = nil
                            dismiss()
                        } label: {
                            Label("Remove Category", systemImage: "xmark.circle")
                        }
                    }
                }

                // Category list
                Section("Categories") {
                    ForEach(categories) { cat in
                        Button {
                            transaction.category = cat
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(cat.color.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: cat.icon)
                                        .foregroundStyle(cat.color)
                                        .imageScale(.small)
                                }
                                Text(cat.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if transaction.category?.id == cat.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }

                // Add new
                Section {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Label("New Category…", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Categorize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("New Category", isPresented: $showingAddCategory) {
                TextField("Category name", text: $newCategoryName)
                Button("Add") {
                    let name = newCategoryName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        modelContext.insert(Category(name: name))
                    }
                    newCategoryName = ""
                }
                Button("Cancel", role: .cancel) { newCategoryName = "" }
            }
            .onAppear { seedCategoriesIfNeeded() }
        }
    }

    private func seedCategoriesIfNeeded() {
        guard categories.isEmpty else { return }
        for (name, colorHex, icon) in DefaultCategories.all {
            modelContext.insert(Category(name: name, colorHex: colorHex, icon: icon))
        }
    }
}
