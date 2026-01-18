import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        NavigationStack {
            if sessionManager.isSessionActive {
                ActiveSessionView()
            } else {
                mainMenuView
            }
        }
    }

    private var mainMenuView: some View {
        List {
            // Recommendation Section
            Section {
                recommendationRow
            }

            // Quick Access - Favorites
            if !sessionManager.favoriteModes.isEmpty {
                Section {
                    ForEach(sessionManager.favoriteModes) { mode in
                        NavigationLink(destination: VibeDetailView(mode: mode)) {
                            ModeRow(mode: mode, showFavorite: false)
                        }
                    }
                } header: {
                    Label("Favorites", systemImage: "star.fill")
                        .foregroundColor(.yellow)
                }
            }

            // Category Sections
            ForEach(VibeCategory.allCases, id: \.self) { category in
                Section {
                    ForEach(VibeMode.modes(for: category)) { mode in
                        NavigationLink(destination: VibeDetailView(mode: mode)) {
                            ModeRow(mode: mode, showFavorite: sessionManager.isFavorite(mode: mode))
                        }
                    }
                } header: {
                    Label(category.rawValue, systemImage: category.icon)
                        .foregroundColor(category.color)
                }
            }

            // Footer Section
            Section {
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gear")
                }

                if sessionManager.currentStreak > 0 {
                    HStack {
                        Label("Streak", systemImage: "flame.fill")
                            .foregroundColor(.orange)
                        Spacer()
                        Text("\(sessionManager.currentStreak) days")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(.carousel)
        .navigationTitle("NeuroCore")
    }

    private var recommendationRow: some View {
        let recommended = sessionManager.recommendedMode()

        return NavigationLink(destination: VibeDetailView(mode: recommended)) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(recommended.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: recommended.icon)
                        .font(.title3)
                        .foregroundColor(recommended.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("Try Now")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }

                    Text(recommended.name)
                        .font(.headline)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Mode Row

struct ModeRow: View {
    let mode: VibeMode
    var showFavorite: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(mode.color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: mode.icon)
                    .font(.body)
                    .foregroundColor(mode.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(mode.name)
                        .font(.headline)

                    if showFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }

                Text(mode.shortDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Category Extension

extension VibeCategory {
    var icon: String {
        switch self {
        case .energize: return "bolt.fill"
        case .focus: return "scope"
        case .relax: return "leaf.fill"
        case .sleep: return "moon.fill"
        }
    }
}

// MARK: - Mode Extension for Short Description

extension VibeMode {
    var shortDescription: String {
        switch pattern {
        case .energy: return "Wake up & energize"
        case .social: return "Feel engaged"
        case .focus: return "Deep concentration"
        case .flow: return "Peak performance"
        case .calm: return "Stress relief"
        case .unwind: return "Release tension"
        case .recover: return "Post-activity rest"
        case .sleep: return "Fall asleep faster"
        case .powerNap: return "Quick recharge"
        case .deepRest: return "Deep relaxation"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionManager())
}
