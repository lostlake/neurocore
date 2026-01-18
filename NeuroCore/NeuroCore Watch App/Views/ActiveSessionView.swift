import SwiftUI
import WatchKit

struct ActiveSessionView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showStopConfirmation = false
    @State private var showBiometricDetail = false
    @Environment(\.isLuminanceReduced) var isLuminanceReduced

    private let device = WKInterfaceDevice.current()

    private var biometricMonitor: BiometricMonitor {
        sessionManager.biometricMonitor
    }

    var body: some View {
        GeometryReader { geometry in
            let ringSize = min(geometry.size.width * 0.6, 110)

            ScrollView {
                VStack(spacing: 12) {
                    if let mode = sessionManager.currentMode {
                        sessionHeader(mode: mode)

                        ZStack {
                            if !isLuminanceReduced && !sessionManager.isPaused {
                                PulsingAnimation(color: mode.color)
                                    .frame(width: ringSize + 24, height: ringSize + 24)
                            }

                            progressRing(mode: mode, size: ringSize)
                        }
                        .frame(height: ringSize + 24)

                        timeDisplay

                        if sessionManager.adaptiveModeEnabled {
                            biometricDisplay(mode: mode)
                        }

                        controlButtons(mode: mode)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .confirmationDialog(
            "End Session?",
            isPresented: $showStopConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Session", role: .destructive) {
                sessionManager.stopSession()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showBiometricDetail) {
            if let mode = sessionManager.currentMode {
                BiometricDetailView(mode: mode)
            }
        }
    }

    private func biometricDisplay(mode: VibeMode) -> some View {
        Button(action: { showBiometricDetail = true }) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(biometricMonitor.stressLevel.color)
                        .frame(width: 8, height: 8)

                    Text(biometricMonitor.stressLevel.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(biometricMonitor.stressLevel.color)
                }

                HStack(spacing: 12) {
                    // Heart Rate
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("\(Int(biometricMonitor.currentHeartRate))")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }

                    // HRV
                    HStack(spacing: 3) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("\(Int(biometricMonitor.currentHRV))ms")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
                .foregroundColor(.secondary)

                // Adaptive Intensity Indicator
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text("Adaptive: \(Int(sessionManager.effectiveIntensity * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.15))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Biometric data: \(biometricMonitor.stressLevel.rawValue), heart rate \(Int(biometricMonitor.currentHeartRate)), HRV \(Int(biometricMonitor.currentHRV)) milliseconds")
        .accessibilityHint("Tap for more details")
    }

    private func sessionHeader(mode: VibeMode) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.body)
                    .foregroundColor(mode.color)
                    .accessibilityHidden(true)

                Text(mode.name)
                    .font(.headline)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(mode.name) session")

            if sessionManager.isPaused {
                Text("PAUSED")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.2))
                    )
                    .accessibilityLabel("Session paused")
            }
        }
    }

    private func progressRing(mode: VibeMode, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)

            Circle()
                .trim(from: 0, to: sessionManager.progress)
                .stroke(
                    mode.color.gradient,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: sessionManager.progress)

            VStack(spacing: 2) {
                Text(sessionManager.formattedRemainingTime)
                    .font(.system(size: size * 0.2, weight: .semibold, design: .monospaced))
                    .minimumScaleFactor(0.7)

                Text("remaining")
                    .font(.system(size: size * 0.1))
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(sessionManager.formattedRemainingTime) remaining")
        }
        .frame(width: size, height: size)
    }

    private var timeDisplay: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("Elapsed")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(sessionManager.formattedElapsedTime)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Elapsed: \(sessionManager.formattedElapsedTime)")

            Divider()
                .frame(height: 20)

            VStack(spacing: 2) {
                Text("Intensity")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("\(Int(sessionManager.intensity * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Intensity: \(Int(sessionManager.intensity * 100)) percent")
        }
    }

    private func controlButtons(mode: VibeMode) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 18) {
                Button(action: adjustIntensityDown) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(sessionManager.intensity <= 0.05 ? .gray.opacity(0.4) : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(sessionManager.intensity <= 0.05)
                .accessibilityLabel("Decrease intensity")
                .accessibilityHint("Currently at \(Int(sessionManager.intensity * 100)) percent")

                Button(action: togglePause) {
                    ZStack {
                        Circle()
                            .fill(mode.color)
                            .frame(width: 46, height: 46)

                        Image(systemName: sessionManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(sessionManager.isPaused ? "Resume session" : "Pause session")

                Button(action: adjustIntensityUp) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(sessionManager.intensity >= 1.0 ? .gray.opacity(0.4) : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(sessionManager.intensity >= 1.0)
                .accessibilityLabel("Increase intensity")
                .accessibilityHint("Currently at \(Int(sessionManager.intensity * 100)) percent")
            }

            Button(action: { showStopConfirmation = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "stop.fill")
                        .font(.caption2)
                    Text("Stop")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.red)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .stroke(Color.red.opacity(0.7), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Stop session")
        }
    }

    private func togglePause() {
        sessionManager.togglePause()
        device.play(sessionManager.isPaused ? .stop : .start)
    }

    private func adjustIntensityDown() {
        guard sessionManager.intensity > 0.05 else { return }
        let newIntensity = max(0.05, sessionManager.intensity - 0.05)
        sessionManager.updateIntensity(newIntensity)
        device.play(.click)
    }

    private func adjustIntensityUp() {
        guard sessionManager.intensity < 1.0 else { return }
        let newIntensity = min(1.0, sessionManager.intensity + 0.05)
        sessionManager.updateIntensity(newIntensity)
        device.play(.click)
    }
}

struct PulsingAnimation: View {
    let color: Color
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .scaleEffect(isPulsing ? 1.1 : 0.95)
                .opacity(isPulsing ? 0.0 : 0.5)

            Circle()
                .fill(color.opacity(0.08))
                .scaleEffect(isPulsing ? 1.0 : 0.85)
                .opacity(isPulsing ? 0.2 : 0.4)
        }
        .animation(
            .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
            value: isPulsing
        )
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Biometric Detail View

struct BiometricDetailView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) var dismiss

    let mode: VibeMode

    private var biometricMonitor: BiometricMonitor {
        sessionManager.biometricMonitor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Biometric Data")
                    .font(.headline)
                    .padding(.top, 8)

                // Stress Level Card
                VStack(spacing: 8) {
                    HStack {
                        Circle()
                            .fill(biometricMonitor.stressLevel.color)
                            .frame(width: 12, height: 12)

                        Text(biometricMonitor.stressLevel.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(biometricMonitor.stressLevel.color)

                        Spacer()
                    }

                    Text(biometricMonitor.stressLevel.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(biometricMonitor.stressLevel.color.opacity(0.15))
                )

                // Metrics Grid
                HStack(spacing: 12) {
                    MetricBox(
                        icon: "heart.fill",
                        iconColor: .red,
                        value: "\(Int(biometricMonitor.currentHeartRate))",
                        unit: "BPM",
                        label: "Heart Rate"
                    )

                    MetricBox(
                        icon: "waveform.path.ecg",
                        iconColor: .green,
                        value: "\(Int(biometricMonitor.currentHRV))",
                        unit: "ms",
                        label: "HRV"
                    )
                }

                // Adaptive Intensity
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                        Text("Adaptive Intensity")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                    }

                    HStack {
                        Text("Base: \(Int(sessionManager.intensity * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("Effective: \(Int(sessionManager.effectiveIntensity * 100))%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(mode.color)
                    }

                    Text(adaptiveExplanation)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                )

                // Toggle Adaptive Mode
                Button(action: {
                    sessionManager.toggleAdaptiveMode()
                }) {
                    HStack {
                        Image(systemName: sessionManager.adaptiveModeEnabled ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(sessionManager.adaptiveModeEnabled ? .green : .secondary)
                        Text(sessionManager.adaptiveModeEnabled ? "Adaptive On" : "Adaptive Off")
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Button("Done") {
                    dismiss()
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            }
            .padding(.horizontal)
        }
    }

    private var adaptiveExplanation: String {
        switch biometricMonitor.stressLevel {
        case .low:
            return "You're relaxed. Intensity lowered for gentle maintenance."
        case .moderate:
            return "Moderate stress detected. Maintaining base intensity."
        case .high:
            return "Elevated stress. Intensity increased to help you relax."
        case .veryHigh:
            return "High stress detected. Maximum therapeutic intensity applied."
        case .unknown:
            return "Gathering biometric data..."
        }
    }
}

struct MetricBox: View {
    let icon: String
    let iconColor: Color
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)

            HStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.15))
        )
    }
}

// MARK: - Stress Level Color Extension

extension BiometricMonitor.StressLevel {
    var color: Color {
        switch self {
        case .low:
            return .green
        case .moderate:
            return .yellow
        case .high:
            return .orange
        case .veryHigh:
            return .red
        case .unknown:
            return .gray
        }
    }

    var description: String {
        switch self {
        case .low:
            return "Your body shows signs of relaxation. Great job!"
        case .moderate:
            return "Normal stress levels. The session is working."
        case .high:
            return "Elevated stress detected. Focus on your breathing."
        case .veryHigh:
            return "High stress detected. Let the vibrations guide you to calm."
        case .unknown:
            return "Measuring your biometrics..."
        }
    }
}

#Preview {
    let manager = SessionManager()
    manager.startSession(mode: VibeMode.allModes[0])

    return ActiveSessionView()
        .environmentObject(manager)
}
