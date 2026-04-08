import Foundation
import SwiftData
import SwiftUI

@Model
final class Category {
    var id: UUID
    var name: String
    var colorHex: String
    var icon: String
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction] = []

    init(name: String, colorHex: String = "007AFF", icon: String = "tag") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// Default categories seeded on first launch
enum DefaultCategories {
    static let all: [(name: String, colorHex: String, icon: String)] = [
        ("Housing",         "FF6B6B", "house.fill"),
        ("Food & Dining",   "FFB347", "fork.knife"),
        ("Transportation",  "4ECDC4", "car.fill"),
        ("Shopping",        "A29BFE", "bag.fill"),
        ("Entertainment",   "FD79A8", "tv.fill"),
        ("Health",          "55EFC4", "heart.fill"),
        ("Utilities",       "74B9FF", "bolt.fill"),
        ("Income",          "00B894", "arrow.down.circle.fill"),
        ("Other",           "636E72", "tag.fill"),
    ]
}

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let value = UInt64(h, radix: 16) else { return nil }
        self.init(
            red:   Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8)  & 0xFF) / 255,
            blue:  Double(value         & 0xFF) / 255
        )
    }
}
