import SwiftUI
import SwiftData

@main
struct BudgetCalcApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Transaction.self, Category.self])
        }
    }
}
