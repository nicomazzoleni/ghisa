import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .insights
    @State private var showingProfile = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                InsightsPlaceholderView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            profileButton
                        }
                    }
            }
            .tabItem {
                Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(AppTab.insights)

            NavigationStack {
                TrainTabView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            profileButton
                        }
                    }
            }
            .tabItem {
                Label("Train", systemImage: "dumbbell")
            }
            .tag(AppTab.train)

            NavigationStack {
                DailyLogView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            profileButton
                        }
                    }
            }
            .tabItem {
                Label("Daily Log", systemImage: "calendar")
            }
            .tag(AppTab.dailyLog)
        }
        .tint(Theme.Accent.primary)
        .sheet(isPresented: $showingProfile) {
            ProfilePlaceholderView()
        }
    }

    private var profileButton: some View {
        Button {
            showingProfile = true
        } label: {
            Image(systemName: "person.circle")
                .font(.title3)
                .foregroundStyle(Theme.Text.secondary)
        }
    }
}

enum AppTab: Hashable {
    case insights
    case train
    case dailyLog
}
