import SwiftUI

struct VibeDetailView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) var dismiss

    let mode: VibeMode
    @State private var intensity: Double = 0.5
    @State private var selectedDuration: TimeInterval = 30 * 60
    @State private var isPreviewing = false

    private let durationOptions: [TimeInterval] = [
        15 * 60,
        30 * 60,
        45 * 60,
        60 * 60,
        90 * 60,
        120 * 60
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                modeHeader

                intensityControl

                durationPicker

                actionButtons
            }
            .padding(.horizontal)
        }
        .navigationTitle(mode.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            intensity = sessionManager.intensity
            selectedDuration = sessionManager.duration
        }
    }

    private var modeHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(mode.color.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: mode.icon)
                    .font(.system(size: 28))
                    .foregroundColor(mode.color)
            }

            Text(mode.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
    }

    private var intensityControl: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Intensity")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(intensity * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(mode.color)
            }

            HStack(spacing: 12) {
                Button(action: decreaseIntensity) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(intensity <= mode.minIntensity ? .gray : mode.color)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(intensity <= mode.minIntensity)

                IntensityBar(
                    value: intensity,
                    range: mode.minIntensity...mode.maxIntensity,
                    color: mode.color
                )

                Button(action: increaseIntensity) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(intensity >= mode.maxIntensity ? .gray : mode.color)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(intensity >= mode.maxIntensity)
            }

            Text(intensityDescription)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
        )
    }

    private var intensityDescription: String {
        if intensity < 0.3 {
            return "Gentle and subtle"
        } else if intensity < 0.6 {
            return "Moderate presence"
        } else if intensity < 0.8 {
            return "Strong sensation"
        } else {
            return "Maximum effect"
        }
    }

    private func decreaseIntensity() {
        let step = 0.05
        intensity = max(mode.minIntensity, intensity - step)
    }

    private func increaseIntensity() {
        let step = 0.05
        intensity = min(mode.maxIntensity, intensity + step)
    }

    private var durationPicker: some View {
        VStack(spacing: 8) {
            Text("Duration")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(durationOptions, id: \.self) { duration in
                        DurationChip(
                            duration: duration,
                            isSelected: selectedDuration == duration,
                            color: mode.color
                        ) {
                            selectedDuration = duration
                        }
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: startSession) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Session")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(mode.color)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: previewVibe) {
                HStack {
                    Image(systemName: isPreviewing ? "stop.fill" : "waveform")
                    Text(isPreviewing ? "Stop Preview" : "Preview")
                }
                .font(.caption)
                .foregroundColor(mode.color)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.top, 8)
    }

    private func startSession() {
        sessionManager.updateIntensity(intensity)
        sessionManager.setDuration(selectedDuration)
        sessionManager.startSession(mode: mode)
        dismiss()
    }

    private func previewVibe() {
        if isPreviewing {
            HapticEngine.shared.stop()
            isPreviewing = false
        } else {
            isPreviewing = true
            HapticEngine.shared.playPreview(for: mode.pattern)

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                isPreviewing = false
            }
        }
    }
}

struct IntensityBar: View {
    let value: Double
    let range: ClosedRange<Double>
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))

                RoundedRectangle(cornerRadius: 4)
                    .fill(color.gradient)
                    .frame(width: geometry.size.width * normalizedValue)
            }
        }
        .frame(height: 8)
    }

    private var normalizedValue: CGFloat {
        let rangeSpan = range.upperBound - range.lowerBound
        guard rangeSpan > 0 else { return 0 }
        return CGFloat((value - range.lowerBound) / rangeSpan)
    }
}

struct DurationChip: View {
    let duration: TimeInterval
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(formattedDuration)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? color : Color.gray.opacity(0.3))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var formattedDuration: String {
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes)m"
    }
}

#Preview {
    NavigationStack {
        VibeDetailView(mode: VibeMode.allModes[0])
            .environmentObject(SessionManager())
    }
}
