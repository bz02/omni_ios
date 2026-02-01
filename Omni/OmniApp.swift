import SwiftUI

@main
struct OmniApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch appState.currentRoute {
                case .onboarding:
                    // Placeholder until we create the file
                    OnboardingView()
                case .home:
                    HomeView()
                }
            }
            .environmentObject(appState)
        }
    }
}
