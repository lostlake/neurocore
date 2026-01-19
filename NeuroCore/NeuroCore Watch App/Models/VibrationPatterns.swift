import Foundation
import WatchKit

enum VibrationPattern: String, CaseIterable {
    case energy
    case social
    case focus
    case flow
    case calm
    case unwind
    case recover
    case sleep
    case powerNap
    case deepRest

    struct HapticEvent {
        let type: WKHapticType
        let delay: TimeInterval
        let intensity: Double
    }

    struct PatternConfig {
        let events: [HapticEvent]
        let cycleDuration: TimeInterval
        let waveform: Waveform
        let baseFrequency: Double
    }

    enum Waveform {
        case sine
        case square
        case triangle
        case sawtooth
        case pulse(duty: Double)

        func amplitude(at phase: Double) -> Double {
            switch self {
            case .sine:
                return sin(phase * 2 * .pi)
            case .square:
                return phase < 0.5 ? 1.0 : -1.0
            case .triangle:
                if phase < 0.25 {
                    return phase * 4
                } else if phase < 0.75 {
                    return 2 - phase * 4
                } else {
                    return phase * 4 - 4
                }
            case .sawtooth:
                return 2 * phase - 1
            case .pulse(let duty):
                return phase < duty ? 1.0 : 0.0
            }
        }
    }

    var config: PatternConfig {
        switch self {
        case .energy:
            return PatternConfig(
                events: [
                    HapticEvent(type: .start, delay: 0, intensity: 0.8),
                    HapticEvent(type: .click, delay: 0.15, intensity: 0.9),
                    HapticEvent(type: .click, delay: 0.3, intensity: 0.85),
                    HapticEvent(type: .directionUp, delay: 0.5, intensity: 0.95),
                    HapticEvent(type: .click, delay: 0.7, intensity: 0.8),
                ],
                cycleDuration: 2.0,
                waveform: .square,
                baseFrequency: 12.0
            )

        case .social:
            return PatternConfig(
                events: [
                    HapticEvent(type: .click, delay: 0, intensity: 0.6),
                    HapticEvent(type: .click, delay: 0.25, intensity: 0.7),
                    HapticEvent(type: .directionUp, delay: 0.5, intensity: 0.65),
                    HapticEvent(type: .click, delay: 0.8, intensity: 0.55),
                ],
                cycleDuration: 2.5,
                waveform: .sine,
                baseFrequency: 8.0
            )

        case .focus:
            return PatternConfig(
                events: [
                    HapticEvent(type: .click, delay: 0, intensity: 0.5),
                    HapticEvent(type: .click, delay: 0.4, intensity: 0.55),
                    HapticEvent(type: .click, delay: 0.8, intensity: 0.5),
                    HapticEvent(type: .click, delay: 1.2, intensity: 0.45),
                ],
                cycleDuration: 3.0,
                waveform: .triangle,
                baseFrequency: 10.0
            )

        case .flow:
            return PatternConfig(
                events: [
                    HapticEvent(type: .click, delay: 0, intensity: 0.4),
                    HapticEvent(type: .click, delay: 0.6, intensity: 0.45),
                    HapticEvent(type: .click, delay: 1.2, intensity: 0.5),
                    HapticEvent(type: .click, delay: 1.8, intensity: 0.45),
                    HapticEvent(type: .click, delay: 2.4, intensity: 0.4),
                ],
                cycleDuration: 4.0,
                waveform: .sine,
                baseFrequency: 7.0
            )

        case .calm:
            return PatternConfig(
                events: [
                    HapticEvent(type: .click, delay: 0, intensity: 0.3),
                    HapticEvent(type: .click, delay: 0.8, intensity: 0.35),
                    HapticEvent(type: .click, delay: 1.6, intensity: 0.3),
                ],
                cycleDuration: 4.0,
                waveform: .sine,
                baseFrequency: 4.0
            )

        case .unwind:
            return PatternConfig(
                events: [
                    HapticEvent(type: .click, delay: 0, intensity: 0.25),
                    HapticEvent(type: .click, delay: 1.0, intensity: 0.3),
                    HapticEvent(type: .click, delay: 2.0, intensity: 0.25),
                ],
                cycleDuration: 5.0,
                waveform: .sine,
                baseFrequency: 3.0
            )

        case .recover:
            return PatternConfig(
                events: [
                    HapticEvent(type: .click, delay: 0, intensity: 0.3),
                    HapticEvent(type: .click, delay: 0.5, intensity: 0.35),
                    HapticEvent(type: .click, delay: 1.5, intensity: 0.3),
                    HapticEvent(type: .click, delay: 2.0, intensity: 0.25),
                ],
                cycleDuration: 4.5,
                waveform: .triangle,
                baseFrequency: 5.0
            )

        case .sleep:
            return PatternConfig(
                events: [
                    HapticEvent(type: .click, delay: 0, intensity: 0.15),
                    HapticEvent(type: .click, delay: 1.5, intensity: 0.2),
                    HapticEvent(type: .click, delay: 3.0, intensity: 0.15),
                ],
                cycleDuration: 6.0,
                waveform: .sine,
                baseFrequency: 2.0
            )

        case .powerNap:
            return PatternConfig(
                events: [
                    HapticEvent(type: .click, delay: 0, intensity: 0.2),
                    HapticEvent(type: .click, delay: 1.0, intensity: 0.25),
                    HapticEvent(type: .click, delay: 2.5, intensity: 0.2),
                ],
                cycleDuration: 5.0,
                waveform: .sine,
                baseFrequency: 3.0
            )

        case .deepRest:
            return PatternConfig(
                events: [
                    HapticEvent(type: .click, delay: 0, intensity: 0.1),
                    HapticEvent(type: .click, delay: 2.0, intensity: 0.12),
                    HapticEvent(type: .click, delay: 4.0, intensity: 0.1),
                ],
                cycleDuration: 8.0,
                waveform: .sine,
                baseFrequency: 1.5
            )
        }
    }

    var hapticSequence: [(WKHapticType, TimeInterval)] {
        config.events.map { ($0.type, $0.delay) }
    }

    func scaledIntensity(_ baseIntensity: Double, userIntensity: Double) -> Double {
        return baseIntensity * userIntensity
    }
}

struct VibrationSequence {
    let pattern: VibrationPattern
    let intensity: Double
    let duration: TimeInterval

    var totalCycles: Int {
        Int(duration / pattern.config.cycleDuration)
    }

    func event(at index: Int) -> VibrationPattern.HapticEvent? {
        let events = pattern.config.events
        guard !events.isEmpty else { return nil }
        return events[index % events.count]
    }
}
