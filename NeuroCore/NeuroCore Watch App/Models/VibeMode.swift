import SwiftUI

enum VibeCategory: String, CaseIterable {
    case energize = "Energize"
    case focus = "Focus"
    case relax = "Relax"
    case sleep = "Sleep"

    var color: Color {
        switch self {
        case .energize: return .orange
        case .focus: return .blue
        case .relax: return .green
        case .sleep: return .purple
        }
    }
}

struct VibeMode: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let category: VibeCategory
    let icon: String
    let pattern: VibrationPattern
    let defaultDuration: TimeInterval
    let minIntensity: Double
    let maxIntensity: Double

    var color: Color {
        category.color
    }

    static func == (lhs: VibeMode, rhs: VibeMode) -> Bool {
        lhs.id == rhs.id
    }

    static let allModes: [VibeMode] = [
        // Energize Category
        VibeMode(
            name: "Energy",
            description: "Boost alertness and wake up your body with invigorating rhythms",
            category: .energize,
            icon: "bolt.fill",
            pattern: .energy,
            defaultDuration: 30 * 60,
            minIntensity: 0.4,
            maxIntensity: 1.0
        ),
        VibeMode(
            name: "Social",
            description: "Feel engaged and at ease for social situations",
            category: .energize,
            icon: "person.2.fill",
            pattern: .social,
            defaultDuration: 45 * 60,
            minIntensity: 0.3,
            maxIntensity: 0.9
        ),

        // Focus Category
        VibeMode(
            name: "Focus",
            description: "Enhance concentration and mental clarity for deep work",
            category: .focus,
            icon: "scope",
            pattern: .focus,
            defaultDuration: 60 * 60,
            minIntensity: 0.3,
            maxIntensity: 0.8
        ),
        VibeMode(
            name: "Flow",
            description: "Enter a productive flow state with sustained attention",
            category: .focus,
            icon: "waveform.path",
            pattern: .flow,
            defaultDuration: 90 * 60,
            minIntensity: 0.25,
            maxIntensity: 0.75
        ),

        // Relax Category
        VibeMode(
            name: "Calm",
            description: "Ease into a peaceful state and reduce stress",
            category: .relax,
            icon: "leaf.fill",
            pattern: .calm,
            defaultDuration: 30 * 60,
            minIntensity: 0.2,
            maxIntensity: 0.6
        ),
        VibeMode(
            name: "Unwind",
            description: "Release tension and transition to relaxation",
            category: .relax,
            icon: "wind",
            pattern: .unwind,
            defaultDuration: 45 * 60,
            minIntensity: 0.15,
            maxIntensity: 0.55
        ),
        VibeMode(
            name: "Recover",
            description: "Support physical and mental recovery after exertion",
            category: .relax,
            icon: "heart.fill",
            pattern: .recover,
            defaultDuration: 30 * 60,
            minIntensity: 0.2,
            maxIntensity: 0.5
        ),

        // Sleep Category
        VibeMode(
            name: "Sleep",
            description: "Gentle vibrations to help you fall asleep faster",
            category: .sleep,
            icon: "moon.fill",
            pattern: .sleep,
            defaultDuration: 60 * 60,
            minIntensity: 0.1,
            maxIntensity: 0.4
        ),
        VibeMode(
            name: "Power Nap",
            description: "Quick rest to recharge during the day",
            category: .sleep,
            icon: "zzz",
            pattern: .powerNap,
            defaultDuration: 20 * 60,
            minIntensity: 0.15,
            maxIntensity: 0.45
        ),
        VibeMode(
            name: "Deep Rest",
            description: "Ultra-gentle patterns for restorative rest",
            category: .sleep,
            icon: "moon.stars.fill",
            pattern: .deepRest,
            defaultDuration: 120 * 60,
            minIntensity: 0.05,
            maxIntensity: 0.3
        )
    ]

    static func modes(for category: VibeCategory) -> [VibeMode] {
        allModes.filter { $0.category == category }
    }
}
