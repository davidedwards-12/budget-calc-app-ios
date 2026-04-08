import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var selectedTab = 0
    @State private var selectedBank = "All Banks"

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab, selectedBank: $selectedBank)
                .tabItem { Label("Dashboard", systemImage: "chart.pie.fill") }
                .tag(0)

            TransactionsListView(selectedBank: $selectedBank)
                .tabItem { Label("Transactions", systemImage: "list.bullet") }
                .tag(1)

            ImportView()
                .tabItem { Label("Import", systemImage: "square.and.arrow.down") }
                .tag(2)
            
            TrendsView(selectedBank: $selectedBank)
                .tabItem { Label("Trends", systemImage: "chart.bar.fill") }
                .tag(3)
        }
        .sheet(isPresented: .constant(!hasSeenOnboarding)) {
            OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
        }
    }
}
