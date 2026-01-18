import SwiftUI

/// App Icon Design for NeuroCore
/// Export at 1024x1024 for App Store
///
/// To export:
/// 1. Run this in an iOS/macOS app or SwiftUI Preview
/// 2. Use a screenshot tool or ImageRenderer to export at 1024x1024
///
struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.1, blue: 0.4),  // Deep purple
                    Color(red: 0.1, green: 0.2, blue: 0.5),  // Deep blue
                    Color(red: 0.05, green: 0.15, blue: 0.3) // Dark blue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle radial glow
            RadialGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.clear
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )

            // Waveform rings
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.6 - Double(i) * 0.15),
                                Color.blue.opacity(0.4 - Double(i) * 0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 24 - CGFloat(i) * 4
                    )
                    .frame(width: 500 + CGFloat(i) * 140, height: 500 + CGFloat(i) * 140)
                    .opacity(0.8 - Double(i) * 0.2)
            }

            // Center pulse
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Color.cyan,
                            Color.blue
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .shadow(color: .cyan.opacity(0.8), radius: 60)

            // Inner glow
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 120, height: 120)
                .blur(radius: 20)
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 224)) // iOS icon radius
    }
}

/// Simplified icon for smaller sizes
struct AppIconSimpleView: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.1, blue: 0.35),
                    Color(red: 0.1, green: 0.15, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Single ring
            Circle()
                .stroke(
                    Color.cyan.opacity(0.7),
                    lineWidth: 16
                )
                .frame(width: 600, height: 600)

            // Center
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color.cyan],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
        }
        .frame(width: 1024, height: 1024)
    }
}

#Preview("App Icon") {
    AppIconView()
        .previewLayout(.fixed(width: 1024, height: 1024))
}

#Preview("App Icon Simple") {
    AppIconSimpleView()
        .previewLayout(.fixed(width: 1024, height: 1024))
}
