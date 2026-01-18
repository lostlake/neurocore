import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showStopConfirmation = false

    var body: some View {
        VStack(spacing: 16) {
            if let mode = sessionManager.currentMode {
                sessionHeader(mode: mode)

                progressRing(mode: mode)

                timeDisplay

                controlButtons(mode: mode)
            }
        }
        .padding()
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
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.title3)
                    .foregroundColor(mode.color)

                Text(mode.name)
                    .font(.headline)
            }

            if sessionManager.isPaused {
                Text("PAUSED")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.2))
                    )
            }
        }
    }

    private func progressRing(mode: VibeMode) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)

            Circle()
                .trim(from: 0, to: sessionManager.progress)
                .stroke(
                    mode.color.gradient,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: sessionManager.progress)

            VStack(spacing: 4) {
                Text(sessionManager.formattedRemainingTime)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.semibold)

                Text("remaining")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 120, height: 120)
    }

    private var timeDisplay: some View {
        HStack(spacing: 20) {
            VStack(spacing: 2) {
                Text("Elapsed")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(sessionManager.formattedElapsedTime)
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Divider()
                .frame(height: 24)

            VStack(spacing: 2) {
                Text("Intensity")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("\(Int(sessionManager.intensity * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }

    private func controlButtons(mode: VibeMode) -> some View {
        HStack(spacing: 20) {
            Button(action: adjustIntensityDown) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { sessionManager.togglePause() }) {
                ZStack {
                    Circle()
                        .fill(mode.color)
                        .frame(width: 50, height: 50)

                    Image(systemName: sessionManager.isPaused ? "play.fill" : "pause.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: adjustIntensityUp) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.top, 8)

        Button(action: { showStopConfirmation = true }) {
            HStack {
                Image(systemName: "stop.fill")
                Text("Stop")
            }
            .font(.caption)
            .foregroundColor(.red)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .stroke(Color.red, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 4)
    }

    private func adjustIntensityDown() {
        let newIntensity = max(0.05, sessionManager.intensity - 0.05)
        sessionManager.updateIntensity(newIntensity)
    }

    private func adjustIntensityUp() {
        let newIntensity = min(1.0, sessionManager.intensity + 0.05)
        sessionManager.updateIntensity(newIntensity)
    }
}

struct PulsingAnimation: View {
    let color: Color
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(color.opacity(0.3))
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 0.0 : 0.5)
            .animation(
                .easeInOut(duration: 2.0).repeatForever(autoreverses: false),
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
