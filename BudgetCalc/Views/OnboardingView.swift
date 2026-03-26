import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "doc.richtext.fill",
            imageColor: .blue,
            title: "Welcome to BudgetCalc",
            body: "Import your bank statements and get a clear picture of where your money goes — all on your device, nothing sent to the cloud."
        ),
        OnboardingPage(
            systemImage: "wand.and.stars",
            imageColor: .purple,
            title: "Auto-Categorized",
            body: "Transactions are automatically tagged the moment you import — Food & Dining, Shopping, Housing, and more. You can always adjust any category by tapping a transaction."
        ),
        OnboardingPage(
            systemImage: "chart.pie.fill",
            imageColor: .green,
            title: "Understand Your Spending",
            body: "See your income vs. expenses, savings rate, top merchants, and a full monthly breakdown — all updated instantly as you import statements."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageView(page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Circle()
                        .fill(i == currentPage ? Color.primary : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.top, 12)

            // Bottom button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    hasSeenOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .interactiveDismissDisabled()
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.imageColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: page.systemImage)
                    .font(.system(size: 52))
                    .foregroundStyle(page.imageColor)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

private struct OnboardingPage {
    let systemImage: String
    let imageColor: Color
    let title: String
    let body: String
}
