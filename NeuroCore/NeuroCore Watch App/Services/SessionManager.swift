import Foundation
import Combine
import HealthKit
import WatchKit

class SessionManager: ObservableObject {
    @Published var activeSession: VibeSession?
    @Published var isSessionActive = false
    @Published var currentMode: VibeMode?
    @Published var intensity: Double = 0.5
    @Published var duration: TimeInterval = 30 * 60
    @Published var elapsedTime: TimeInterval = 0
    @Published var isPaused = false
    @Published var recentSessions: [SessionRecord] = []

    private let hapticEngine = HapticEngine.shared
    private var sessionTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let healthStore = HKHealthStore()

    private let userDefaults = UserDefaults.standard
    private let intensityKey = "neurocore.intensity"
    private let durationKey = "neurocore.duration"
    private let sessionsKey = "neurocore.sessions"

    init() {
        loadUserPreferences()
        loadSessionHistory()
        setupHealthKit()
    }

    func startSession(mode: VibeMode) {
        stopSession()

        currentMode = mode
        activeSession = VibeSession(mode: mode, intensity: intensity, duration: duration)
        isSessionActive = true
        isPaused = false
        elapsedTime = 0

        hapticEngine.start(
            pattern: mode.pattern,
            intensity: intensity,
            duration: duration
        )

        startSessionTimer()
        requestExtendedRuntime()
    }

    func stopSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        hapticEngine.stop()

        if let session = activeSession {
            let record = SessionRecord(
                mode: currentMode?.name ?? "Unknown",
                category: currentMode?.category.rawValue ?? "Unknown",
                duration: elapsedTime,
                intensity: intensity,
                completedAt: Date()
            )
            saveSessionRecord(record)
        }

        activeSession = nil
        isSessionActive = false
        currentMode = nil
        elapsedTime = 0
        isPaused = false
    }

    func pauseSession() {
        guard isSessionActive, !isPaused else { return }
        isPaused = true
        hapticEngine.pause()
        sessionTimer?.invalidate()
    }

    func resumeSession() {
        guard isSessionActive, isPaused else { return }
        isPaused = false
        hapticEngine.resume()
        startSessionTimer()
    }

    func togglePause() {
        if isPaused {
            resumeSession()
        } else {
            pauseSession()
        }
    }

    func updateIntensity(_ newIntensity: Double) {
        intensity = max(0.05, min(1.0, newIntensity))
        hapticEngine.updateIntensity(intensity)
        saveUserPreferences()
    }

    func setDuration(_ newDuration: TimeInterval) {
        duration = max(5 * 60, min(120 * 60, newDuration))
        saveUserPreferences()
    }

    var remainingTime: TimeInterval {
        max(0, duration - elapsedTime)
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1.0, elapsedTime / duration)
    }

    var formattedRemainingTime: String {
        formatTime(remainingTime)
    }

    var formattedElapsedTime: String {
        formatTime(elapsedTime)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startSessionTimer() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }

            self.elapsedTime += 1

            if self.elapsedTime >= self.duration {
                self.onSessionComplete()
            }
        }
    }

    private func onSessionComplete() {
        WKInterfaceDevice.current().play(.notification)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WKInterfaceDevice.current().play(.success)
        }

        stopSession()
    }

    private func loadUserPreferences() {
        if let savedIntensity = userDefaults.object(forKey: intensityKey) as? Double {
            intensity = savedIntensity
        }
        if let savedDuration = userDefaults.object(forKey: durationKey) as? Double {
            duration = savedDuration
        }
    }

    private func saveUserPreferences() {
        userDefaults.set(intensity, forKey: intensityKey)
        userDefaults.set(duration, forKey: durationKey)
    }

    private func loadSessionHistory() {
        if let data = userDefaults.data(forKey: sessionsKey),
           let sessions = try? JSONDecoder().decode([SessionRecord].self, from: data) {
            recentSessions = sessions.suffix(50).reversed()
        }
    }

    private func saveSessionRecord(_ record: SessionRecord) {
        recentSessions.insert(record, at: 0)
        if recentSessions.count > 50 {
            recentSessions = Array(recentSessions.prefix(50))
        }

        if let data = try? JSONEncoder().encode(recentSessions) {
            userDefaults.set(data, forKey: sessionsKey)
        }
    }

    private func setupHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToRead: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                print("HealthKit authorization granted")
            }
        }
    }

    private func requestExtendedRuntime() {
        let session = WKExtendedRuntimeSession()
        session.start()
    }

    func fetchRecentHRV(completion: @escaping (Double?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(nil)
            return
        }

        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: hrvType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }

            let hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            completion(hrv)
        }

        healthStore.execute(query)
    }

    func totalSessionTime(last days: Int = 7) -> TimeInterval {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return recentSessions
            .filter { $0.completedAt >= cutoff }
            .reduce(0) { $0 + $1.duration }
    }

    func sessionsCount(last days: Int = 7) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return recentSessions.filter { $0.completedAt >= cutoff }.count
    }
}

struct VibeSession {
    let id = UUID()
    let mode: VibeMode
    let intensity: Double
    let duration: TimeInterval
    let startedAt = Date()
}

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let mode: String
    let category: String
    let duration: TimeInterval
    let intensity: Double
    let completedAt: Date

    init(mode: String, category: String, duration: TimeInterval, intensity: Double, completedAt: Date) {
        self.id = UUID()
        self.mode = mode
        self.category = category
        self.duration = duration
        self.intensity = intensity
        self.completedAt = completedAt
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: completedAt)
    }
}
