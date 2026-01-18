import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedCategory: VibeCategory = .relax

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
        ScrollView {
            VStack(spacing: 16) {
                headerView

                recommendationCard

                if !sessionManager.favorites.isEmpty {
                    favoritesSection
                }

                categoryPicker

                modesGrid

                statsView

                NavigationLink(destination: SettingsView()) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal)
        }
        .navigationTitle("NeuroCore")
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(selectedCategory.color.gradient)

            Text("Choose Your Vibe")
                .font(.headline)
                .foregroundColor(.primary)

            if sessionManager.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(sessionManager.currentStreak) day streak")
                        .foregroundColor(.secondary)
                }
                .font(.caption2)
            }
        }
        .padding(.vertical, 8)
    }

    private var recommendationCard: some View {
        let recommended = sessionManager.recommendedMode()

        return NavigationLink(destination: VibeDetailView(mode: recommended)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("Recommended for You")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                }

                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(recommended.color.opacity(0.2))
                            .frame(width: 36, height: 36)

                        Image(systemName: recommended.icon)
                            .font(.system(size: 16))
                            .foregroundColor(recommended.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(recommended.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(sessionManager.recommendationReason())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [recommended.color.opacity(0.15), recommended.color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(recommended.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Favorites")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sessionManager.favoriteModes) { mode in
                        NavigationLink(destination: VibeDetailView(mode: mode)) {
                            FavoriteChip(mode: mode)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(VibeCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }

    private var modesGrid: some View {
        VStack(spacing: 10) {
            ForEach(VibeMode.modes(for: selectedCategory)) { mode in
                NavigationLink(destination: VibeDetailView(mode: mode)) {
                    ModeCard(mode: mode, isFavorite: sessionManager.isFavorite(mode: mode))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var statsView: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.vertical, 4)

            HStack {
                StatItem(
                    icon: "clock.fill",
                    value: formatTotalTime(sessionManager.totalSessionTime()),
                    label: "This Week"
                )

                Spacer()

                StatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(sessionManager.sessionsCount())",
                    label: "Sessions"
                )

                if sessionManager.longestStreak > 0 {
                    Spacer()

                    StatItem(
                        icon: "flame.fill",
                        value: "\(sessionManager.longestStreak)",
                        label: "Best Streak"
                    )
                }
            }
            .font(.caption2)
        }
        .padding(.top, 8)
    }

    private func formatTotalTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct FavoriteChip: View {
    let mode: VibeMode

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: mode.icon)
                .font(.caption)
                .foregroundColor(mode.color)

            Text(mode.name)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(mode.color.opacity(0.2))
        )
        .overlay(
            Capsule()
                .stroke(mode.color.opacity(0.4), lineWidth: 1)
        )
    }
}

struct CategoryButton: View {
    let category: VibeCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? category.color : Color.gray.opacity(0.3))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModeCard: View {
    let mode: VibeMode
    var isFavorite: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(mode.color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: mode.icon)
                    .font(.system(size: 18))
                    .foregroundColor(mode.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(mode.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }

                Text(mode.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
        )
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(value)
                    .fontWeight(.semibold)
            }
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionManager())
}
