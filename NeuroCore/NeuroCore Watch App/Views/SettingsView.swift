import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var defaultIntensity: Double = 0.5
    @State private var defaultDuration: TimeInterval = 30 * 60

    private let durationOptions: [(String, TimeInterval)] = [
        ("15 min", 15 * 60),
        ("30 min", 30 * 60),
        ("45 min", 45 * 60),
        ("1 hour", 60 * 60),
        ("1.5 hours", 90 * 60),
        ("2 hours", 120 * 60)
    ]

    var body: some View {
        List {
            // Adaptive Mode Section
            Section {
                Toggle(isOn: Binding(
                    get: { sessionManager.adaptiveModeEnabled },
                    set: { _ in sessionManager.toggleAdaptiveMode() }
                )) {
                    Label {
                        Text("Adaptive")
                    } icon: {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                    }
                }

                if sessionManager.adaptiveModeEnabled {
                    HStack {
                        Label("Status", systemImage: "heart.fill")
                            .foregroundColor(.red)
                        Spacer()
                        Text(sessionManager.biometricMonitor.stressLevel.rawValue)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Biometric")
            }

            // Defaults Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Intensity")
                        Spacer()
                        Text("\(Int(defaultIntensity * 100))%")
                            .foregroundColor(.blue)
                    }
                    Slider(value: $defaultIntensity, in: 0.1...1.0, step: 0.05)
                        .tint(.blue)
                        .onChange(of: defaultIntensity) { _, newValue in
                            sessionManager.updateIntensity(newValue)
                        }
                }

                Picker("Duration", selection: $defaultDuration) {
                    ForEach(durationOptions, id: \.1) { option in
                        Text(option.0).tag(option.1)
                    }
                }
                .onChange(of: defaultDuration) { _, newValue in
                    sessionManager.setDuration(newValue)
                }
            } header: {
                Text("Defaults")
            }

            // Scheduled Section
            Section {
                if sessionManager.scheduledSessions.isEmpty {
                    Label("No schedules", systemImage: "calendar")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(sessionManager.scheduledSessions.enumerated()), id: \.element.id) { index, session in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.modeName)
                                    .font(.headline)
                                Text(session.formattedTime)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: {
                                sessionManager.removeScheduledSession(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            } header: {
                Text("Scheduled")
            }

            // Stats Section
            Section {
                HStack {
                    Label("This Week", systemImage: "clock.fill")
                    Spacer()
                    Text(formatTotalTime(sessionManager.totalSessionTime()))
                        .foregroundColor(.blue)
                }

                HStack {
                    Label("Sessions", systemImage: "checkmark.circle.fill")
                    Spacer()
                    Text("\(sessionManager.sessionsCount())")
                        .foregroundColor(.secondary)
                }

                NavigationLink(destination: SessionHistoryView()) {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            } header: {
                Text("Activity")
            }

            // Streak Section
            Section {
                HStack {
                    Label("Current", systemImage: "flame.fill")
                        .foregroundColor(.orange)
                    Spacer()
                    Text("\(sessionManager.currentStreak) days")
                }

                HStack {
                    Label("Best", systemImage: "trophy.fill")
                        .foregroundColor(.yellow)
                    Spacer()
                    Text("\(sessionManager.longestStreak) days")
                }
            } header: {
                Text("Streaks")
            }

            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            defaultIntensity = sessionManager.intensity
            defaultDuration = sessionManager.duration
        }
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

// MARK: - Session History View

struct SessionHistoryView: View {
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        List {
            if sessionManager.recentSessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)

                    Text("No sessions yet")
                        .font(.headline)

                    Text("Complete a session to see your history")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(sessionManager.recentSessions) { record in
                    SessionRecordRow(record: record)
                }
            }
        }
        .navigationTitle("History")
    }
}

struct SessionRecordRow: View {
    let record: SessionRecord

    var categoryColor: Color {
        switch record.category {
        case "Energize": return .orange
        case "Focus": return .blue
        case "Relax": return .green
        case "Sleep": return .purple
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(categoryColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.mode)
                    .font(.headline)

                Text(record.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(record.formattedDuration)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(SessionManager())
    }
}
