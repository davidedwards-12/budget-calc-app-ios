import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]
    
    @State private var customName = ""
    @State private var customColor: Color = .blue
    @State private var customIcon = ""
    
    let colors: [Color] = [.red, .orange, .yellow, .green, .teal, .blue, .indigo, .purple, .pink, .gray]
    let icons = ["cart", "house", "car", "fork.knife", "gamecontroller", "heart", "airplane", "book", "music.note", "bag", "creditcard", "gift", "dog", "dumbbell", "scissors", "tram", "cross.case", "film", "bolt", "leaf"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category Name", text: $customName)
                }
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if customColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    .onTapGesture { customColor = color }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(icon == customIcon ? customColor.opacity(0.2) : Color(.systemGray5))
                                    .frame(width: 48, height: 48)
                                Image(systemName: icon)
                                    .foregroundStyle(icon == customIcon ? customColor : .secondary)
                            }
                            .onTapGesture { customIcon = icon }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let name = customName.trimmingCharacters(in: .whitespaces)
                        modelContext.insert(Category(name: name, colorHex: customColor.toHex(), icon: customIcon))
                        dismiss()
                    }
                        .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty || customIcon.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddCategoryView()
}
