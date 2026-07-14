import SwiftUI

enum TabBarStyling {
    static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.navy)

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.65)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white
        ]

        [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance]
            .forEach { item in
                item.normal.iconColor = UIColor.white.withAlphaComponent(0.65)
                item.normal.titleTextAttributes = normalAttributes
                item.selected.iconColor = UIColor.white
                item.selected.titleTextAttributes = selectedAttributes
            }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = .white
        UITabBar.appearance().unselectedItemTintColor = UIColor.white.withAlphaComponent(0.65)
    }
}

struct AppRouter: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house") }

            NavigationStack {
                ExerciseListView()
            }
            .tabItem { Label("Exercises", systemImage: "figure.strengthtraining.traditional") }

            NavigationStack {
                RoutineListView()
            }
            .tabItem { Label("Routines", systemImage: "list.bullet") }

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("History", systemImage: "clock") }

            NavigationStack {
                CardScannerView()
            }
            .tabItem { Label("Scan Card", systemImage: "camera.viewfinder") }
        }
        .toolbarBackground(AppTheme.navy, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

#Preview {
    AppRouter()
}
