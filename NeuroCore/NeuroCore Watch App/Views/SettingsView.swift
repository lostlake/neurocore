import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var defaultIntensity: Double = 0.5
    @State private var defaultDuration: TimeInterval = 30 * 60
    @State private var hapticFeedback = true
    @State private var showHistory = false

    private let durationOptions: [(String, TimeInterval)] = [
        ("15 min", 15 * 60),
        ("30 min", 30 * 60),
        ("45 min", 45 * 60),
        ("1 hour", 60 * 60),
        ("1.5 hours", 90 * 60),
        ("2 hours", 120 * 60)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                adaptiveModeSection

                defaultsSection

                scheduledSection

                historySection

                streakSection

                aboutSection
            }
            .padding(.horizontal)
        }
        .navigationTitle("Settings")
        .onAppear {
            defaultIntensity = sessionManager.intensity
            defaultDuration = sessionManager.duration
        }
    }

    private var adaptiveModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Adaptive Mode")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text("Biometric Adaptive")
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        Text("Auto-adjusts intensity based on heart rate and HRV")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Button(action: {
                        sessionManager.toggleAdaptiveMode()
                    }) {
                        Image(systemName: sessionManager.adaptiveModeEnabled ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(sessionManager.adaptiveModeEnabled ? .green : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                if sessionManager.adaptiveModeEnabled {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Current Status")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                        }

                        HStack(spacing: 12) {
                            // Heart Rate
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                Text("\(Int(sessionManager.biometricMonitor.currentHeartRate)) BPM")
                                    .font(.caption2)
                            }

                            // HRV
                            HStack(spacing: 4) {
                                Image(systemName: "waveform.path.ecg")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text("\(Int(sessionManager.biometricMonitor.currentHRV)) ms")
                                    .font(.caption2)
                            }
                        }

                        HStack(spacing: 6) {
                            Circle()
                                .fill(stressLevelColor)
                                .frame(width: 8, height: 8)
                            Text("Stress: \(sessionManager.biometricMonitor.stressLevel.rawValue)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
            )
        }
    }

    private var stressLevelColor: Color {
        switch sessionManager.biometricMonitor.stressLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        case .unknown: return .gray
        }
    }

    private var defaultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Defaults")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    HStack {
                        Text("Intensity")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(defaultIntensity * 100))%")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    Slider(value: $defaultIntensity, in: 0.1...1.0, step: 0.05)
                        .tint(.blue)
                        .onChange(of: defaultIntensity) { _, newValue in
                            sessionManager.updateIntensity(newValue)
                        }
                }

                Divider()

                VStack(spacing: 8) {
                    Text("Default Duration")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("Duration", selection: $defaultDuration) {
                        ForEach(durationOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 60)
                    .onChange(of: defaultDuration) { _, newValue in
                        sessionManager.setDuration(newValue)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
            )
        }
    }

    private var scheduledSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scheduled")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if !sessionManager.scheduledSessions.isEmpty {
                    Text("\(sessionManager.scheduledSessions.count)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue))
                }
            }

            VStack(spacing: 8) {
                if sessionManager.scheduledSessions.isEmpty {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.secondary)
                        Text("No scheduled sessions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    ForEach(Array(sessionManager.scheduledSessions.enumerated()), id: \.element.id) { index, session in
                        ScheduledSessionRow(
                            session: session,
                            onToggle: { sessionManager.toggleScheduledSession(at: index) },
                            onDelete: { sessionManager.removeScheduledSession(at: index) }
                        )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
            )
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly Stats")
                            .font(.caption)
                            .fontWeight(.medium)

                        Text("\(sessionManager.sessionsCount()) sessions")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(formatTotalTime(sessionManager.totalSessionTime()))
                        .font(.headline)
                        .foregroundColor(.blue)
                }

                if let mostUsed = sessionManager.mostUsedMode() {
                    Divider()

                    HStack {
                        Text("Most Used")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(mostUsed)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }

                Divider()

                NavigationLink(destination: SessionHistoryView()) {
                    HStack {
                        Text("View All Sessions")
                            .font(.caption)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
            )
        }
    }

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(sessionManager.currentStreak)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Text("Current")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("\(sessionManager.longestStreak)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Text("Best")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
            )
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                HStack {
                    Text("NeuroCore")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text("v1.0.0")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text("Apollo Neuro-inspired haptic wellness for Apple Watch. Uses gentle vibration patterns to help manage stress, improve focus, and enhance sleep.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
            )
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

struct ScheduledSessionRow: View {
    let session: ScheduledSession
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.modeName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(session.isEnabled ? .primary : .secondary)

                HStack(spacing: 4) {
                    Text(session.formattedTime)
                    Text("•")
                    Text(session.repeatDescription)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onToggle) {
                Image(systemName: session.isEnabled ? "bell.fill" : "bell.slash")
                    .font(.caption)
                    .foregroundColor(session.isEnabled ? .blue : .secondary)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

struct SessionHistoryView: View {
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if sessionManager.recentSessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)

                        Text("No sessions yet")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Complete a session to see your history")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(sessionManager.recentSessions) { record in
                        SessionRecordRow(record: record)
                    }
                }
            }
            .padding(.horizontal)
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
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.mode)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(record.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(record.formattedDuration)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("\(Int(record.intensity * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(SessionManager())
    }
}
