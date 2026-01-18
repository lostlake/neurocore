import Foundation
import WatchKit
import Combine

class HapticEngine: ObservableObject {
    static let shared = HapticEngine()

    @Published private(set) var isPlaying = false
    @Published private(set) var currentPattern: VibrationPattern?
    @Published var intensity: Double = 0.5

    private var hapticTimer: Timer?
    private var patternTimer: Timer?
    private var currentEventIndex = 0
    private var cycleCount = 0
    private var totalCycles = 0
    private var currentSequence: VibrationSequence?
    private var breathPhase: Double = 0
    private var breathDirection: Double = 1

    private let device = WKInterfaceDevice.current()

    private init() {}

    func start(pattern: VibrationPattern, intensity: Double, duration: TimeInterval) {
        stop()

        self.intensity = intensity
        self.currentPattern = pattern
        self.isPlaying = true
        self.currentEventIndex = 0
        self.cycleCount = 0
        self.breathPhase = 0
        self.breathDirection = 1

        let sequence = VibrationSequence(pattern: pattern, intensity: intensity, duration: duration)
        self.currentSequence = sequence
        self.totalCycles = sequence.totalCycles

        startPatternCycle()
    }

    func stop() {
        hapticTimer?.invalidate()
        hapticTimer = nil
        patternTimer?.invalidate()
        patternTimer = nil
        isPlaying = false
        currentPattern = nil
        currentSequence = nil
        currentEventIndex = 0
        cycleCount = 0
    }

    func pause() {
        hapticTimer?.invalidate()
        hapticTimer = nil
        patternTimer?.invalidate()
        patternTimer = nil
        isPlaying = false
    }

    func resume() {
        guard currentSequence != nil else { return }
        isPlaying = true
        startPatternCycle()
    }

    func updateIntensity(_ newIntensity: Double) {
        self.intensity = max(0.05, min(1.0, newIntensity))
    }

    private func startPatternCycle() {
        guard let sequence = currentSequence, isPlaying else { return }

        let config = sequence.pattern.config
        currentEventIndex = 0

        scheduleEvents(for: sequence)

        patternTimer = Timer.scheduledTimer(withTimeInterval: config.cycleDuration, repeats: true) { [weak self] _ in
            self?.onCycleComplete()
        }
    }

    private func scheduleEvents(for sequence: VibrationSequence) {
        let events = sequence.pattern.config.events

        for (index, event) in events.enumerated() {
            let delay = event.delay

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, self.isPlaying else { return }
                self.playHaptic(event: event)
            }
        }

        scheduleBreathModulation(for: sequence)
    }

    private func scheduleBreathModulation(for sequence: VibrationSequence) {
        let modulationInterval = 0.1
        let config = sequence.pattern.config

        hapticTimer = Timer.scheduledTimer(withTimeInterval: modulationInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }

            self.breathPhase += modulationInterval / config.cycleDuration
            if self.breathPhase >= 1.0 {
                self.breathPhase = 0
            }

            let waveAmplitude = config.waveform.amplitude(at: self.breathPhase)
            let modulatedIntensity = self.intensity * (0.8 + 0.2 * waveAmplitude)

            if self.shouldPlaySubtleHaptic(amplitude: waveAmplitude) {
                self.playSubtleHaptic(intensity: modulatedIntensity)
            }
        }
    }

    private func shouldPlaySubtleHaptic(amplitude: Double) -> Bool {
        guard let pattern = currentPattern else { return false }

        let threshold: Double
        switch pattern {
        case .energy, .social:
            threshold = 0.3
        case .focus, .flow:
            threshold = 0.4
        case .calm, .unwind, .recover:
            threshold = 0.5
        case .sleep, .powerNap, .deepRest:
            threshold = 0.6
        }

        return abs(amplitude) > threshold && Double.random(in: 0...1) < 0.15
    }

    private func playSubtleHaptic(intensity: Double) {
        if intensity > 0.3 {
            device.play(.click)
        }
    }

    private func playHaptic(event: VibrationPattern.HapticEvent) {
        let scaledIntensity = event.intensity * intensity

        guard scaledIntensity > 0.1 else { return }

        let hapticType = selectHapticType(for: event.type, intensity: scaledIntensity)
        device.play(hapticType)

        if scaledIntensity > 0.7 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.device.play(.click)
            }
        }
    }

    private func selectHapticType(for type: WKHapticType, intensity: Double) -> WKHapticType {
        if intensity < 0.3 {
            return .click
        } else if intensity < 0.6 {
            return type
        } else {
            switch type {
            case .click:
                return .directionUp
            case .directionUp, .directionDown:
                return .notification
            default:
                return type
            }
        }
    }

    private func onCycleComplete() {
        cycleCount += 1

        if totalCycles > 0 && cycleCount >= totalCycles {
            stop()
            return
        }

        guard let sequence = currentSequence, isPlaying else { return }
        scheduleEvents(for: sequence)
    }

    func playPreview(for pattern: VibrationPattern) {
        let previewDuration: TimeInterval = 3.0
        start(pattern: pattern, intensity: 0.6, duration: previewDuration)

        DispatchQueue.main.asyncAfter(deadline: .now() + previewDuration) { [weak self] in
            self?.stop()
        }
    }

    var progress: Double {
        guard totalCycles > 0 else { return 0 }
        return Double(cycleCount) / Double(totalCycles)
    }

    var remainingTime: TimeInterval {
        guard let sequence = currentSequence else { return 0 }
        let elapsed = Double(cycleCount) * sequence.pattern.config.cycleDuration
        return max(0, sequence.duration - elapsed)
    }
}

extension HapticEngine {
    func createAdaptivePattern(basePattern: VibrationPattern, hrv: Double?) -> VibrationPattern {
        guard let hrv = hrv else { return basePattern }

        if hrv < 30 {
            switch basePattern {
            case .energy, .social, .focus:
                return .calm
            default:
                return basePattern
            }
        } else if hrv > 80 {
            return basePattern
        } else {
            return basePattern
        }
    }
}
