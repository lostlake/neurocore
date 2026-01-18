import SwiftUI
import WatchKit

struct ActiveSessionView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showStopConfirmation = false
    @Environment(\.isLuminanceReduced) var isLuminanceReduced

    private let device = WKInterfaceDevice.current()

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

#Preview {
    let manager = SessionManager()
    manager.startSession(mode: VibeMode.allModes[0])

    return ActiveSessionView()
        .environmentObject(manager)
}
