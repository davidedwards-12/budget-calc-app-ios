import SwiftUI
import SwiftData

struct CategoryPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]

    let transaction: Transaction

    @State private var showingAddCategory = false

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

                categoryList

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
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
        }
    }
    
    private var categoryList: some View {
        let defaultNames = DefaultCategories.all.map { $0.0 }
        let defaultCategories = categories.filter { defaultNames.contains($0.name) }
        let customCategories = categories.filter { !defaultNames.contains($0.name) }

        return Section("Categories") {
            ForEach(defaultCategories) { cat in
                categoryRow(cat)
            }
            ForEach(customCategories) { cat in
                categoryRow(cat)
            }
            .onDelete { offsets in
                for i in offsets {
                    modelContext.delete(customCategories[i])
                }
            }
        }
    }

    private func categoryRow(_ cat: Category) -> some View {
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
