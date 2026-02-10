import Foundation
import Combine
import HealthKit
import WatchKit
import UserNotifications

class SessionManager: ObservableObject {
    @Published var activeSession: VibeSession?
    @Published var isSessionActive = false
    @Published var currentMode: VibeMode?
    @Published var intensity: Double = 0.5
    @Published var duration: TimeInterval = 30 * 60
    @Published var elapsedTime: TimeInterval = 0
    @Published var isPaused = false
    @Published var recentSessions: [SessionRecord] = []
    @Published var favorites: [String] = []
    @Published var scheduledSessions: [ScheduledSession] = []
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0

    // Adaptive Mode
    @Published var adaptiveModeEnabled: Bool = true
    @Published var currentAdaptiveIntensity: Double = 0.5
    @Published var lastBiometricUpdate: Date?

    private let hapticEngine = HapticEngine.shared
    let biometricMonitor = BiometricMonitor.shared
    private var sessionTimer: Timer?
    private var adaptiveTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let healthStore = HKHealthStore()
    private var extendedRuntimeSession: WKExtendedRuntimeSession?

    private let userDefaults = UserDefaults.standard
    private let intensityKey = "neurocore.intensity"
    private let durationKey = "neurocore.duration"
    private let sessionsKey = "neurocore.sessions"
    private let favoritesKey = "neurocore.favorites"
    private let scheduledKey = "neurocore.scheduled"
    private let streakKey = "neurocore.streak"
    private let longestStreakKey = "neurocore.longestStreak"
    private let lastSessionDateKey = "neurocore.lastSessionDate"
    private let adaptiveModeKey = "neurocore.adaptiveMode"

    init() {
        loadUserPreferences()
        loadSessionHistory()
        loadFavorites()
        loadScheduledSessions()
        loadStreakData()
        setupHealthKit()
        requestNotificationPermission()
        setupBiometricObserver()
    }

    private func setupBiometricObserver() {
        biometricMonitor.$adaptiveIntensityAdjustment
            .receive(on: DispatchQueue.main)
            .sink { [weak self] adjustment in
                self?.updateAdaptiveIntensity()
            }
            .store(in: &cancellables)
    }

    private func updateAdaptiveIntensity() {
        guard adaptiveModeEnabled, isSessionActive, let mode = currentMode else { return }

        let adaptedIntensity = biometricMonitor.getAdaptiveIntensity(
            baseIntensity: intensity,
            mode: mode
        )

        if abs(adaptedIntensity - currentAdaptiveIntensity) > 0.02 {
            currentAdaptiveIntensity = adaptedIntensity
            hapticEngine.updateIntensity(currentAdaptiveIntensity)
            lastBiometricUpdate = Date()
        }
    }

    // MARK: - Session Control

    func startSession(mode: VibeMode) {
        stopSession()

        currentMode = mode
        currentAdaptiveIntensity = intensity
        activeSession = VibeSession(mode: mode, intensity: intensity, duration: duration)
        isSessionActive = true
        isPaused = false
        elapsedTime = 0

        let startingIntensity = adaptiveModeEnabled ? currentAdaptiveIntensity : intensity

        hapticEngine.start(
            pattern: mode.pattern,
            intensity: startingIntensity,
            duration: duration
        )

        startSessionTimer()
        requestExtendedRuntime()

        if adaptiveModeEnabled {
            biometricMonitor.startMonitoring()
        }
    }

    func stopSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        adaptiveTimer?.invalidate()
        adaptiveTimer = nil
        hapticEngine.stop()
        endExtendedRuntime()

        if adaptiveModeEnabled {
            biometricMonitor.stopMonitoring()
        }

        if activeSession != nil {
            let record = SessionRecord(
                mode: currentMode?.name ?? "Unknown",
                category: currentMode?.category.rawValue ?? "Unknown",
                duration: elapsedTime,
                intensity: adaptiveModeEnabled ? currentAdaptiveIntensity : intensity,
                completedAt: Date()
            )
            saveSessionRecord(record)
            updateStreak()
        }

        activeSession = nil
        isSessionActive = false
        currentMode = nil
        elapsedTime = 0
        isPaused = false
        lastBiometricUpdate = nil
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

    // MARK: - Time Formatting

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

    // MARK: - Session Timer

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

    // MARK: - Favorites

    func toggleFavorite(mode: VibeMode) {
        if favorites.contains(mode.name) {
            favorites.removeAll { $0 == mode.name }
        } else {
            favorites.append(mode.name)
        }
        saveFavorites()
    }

    func isFavorite(mode: VibeMode) -> Bool {
        favorites.contains(mode.name)
    }

    var favoriteModes: [VibeMode] {
        VibeMode.allModes.filter { favorites.contains($0.name) }
    }

    private func loadFavorites() {
        favorites = userDefaults.stringArray(forKey: favoritesKey) ?? []
    }

    private func saveFavorites() {
        userDefaults.set(favorites, forKey: favoritesKey)
    }

    // MARK: - Smart Recommendations

    func recommendedMode() -> VibeMode {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<9:
            return VibeMode.allModes.first { $0.pattern == .energy } ?? VibeMode.allModes[0]
        case 9..<12:
            return VibeMode.allModes.first { $0.pattern == .focus } ?? VibeMode.allModes[0]
        case 12..<14:
            return VibeMode.allModes.first { $0.pattern == .social } ?? VibeMode.allModes[0]
        case 14..<18:
            return VibeMode.allModes.first { $0.pattern == .flow } ?? VibeMode.allModes[0]
        case 18..<20:
            return VibeMode.allModes.first { $0.pattern == .unwind } ?? VibeMode.allModes[0]
        case 20..<22:
            return VibeMode.allModes.first { $0.pattern == .calm } ?? VibeMode.allModes[0]
        case 22..<24, 0..<5:
            return VibeMode.allModes.first { $0.pattern == .sleep } ?? VibeMode.allModes[0]
        default:
            return VibeMode.allModes.first { $0.pattern == .calm } ?? VibeMode.allModes[0]
        }
    }

    func recommendationReason() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<9:
            return "Good morning! Boost your energy to start the day."
        case 9..<12:
            return "Peak focus time. Enhance your concentration."
        case 12..<14:
            return "Midday break. Feel engaged and social."
        case 14..<18:
            return "Afternoon productivity. Enter your flow state."
        case 18..<20:
            return "Evening wind-down. Release the day's tension."
        case 20..<22:
            return "Relaxation time. Ease into calm."
        case 22..<24, 0..<5:
            return "Bedtime. Gentle vibes for better sleep."
        default:
            return "Take a moment to relax."
        }
    }

    // MARK: - Scheduled Sessions

    func scheduleSession(mode: VibeMode, time: Date, repeatDays: Set<Int>) {
        let scheduled = ScheduledSession(
            modeName: mode.name,
            time: time,
            repeatDays: repeatDays,
            isEnabled: true
        )
        scheduledSessions.append(scheduled)
        saveScheduledSessions()
        scheduleNotification(for: scheduled)
    }

    func removeScheduledSession(at index: Int) {
        guard index < scheduledSessions.count else { return }
        let session = scheduledSessions[index]
        cancelNotification(for: session)
        scheduledSessions.remove(at: index)
        saveScheduledSessions()
    }

    func toggleScheduledSession(at index: Int) {
        guard index < scheduledSessions.count else { return }
        scheduledSessions[index].isEnabled.toggle()
        saveScheduledSessions()

        if scheduledSessions[index].isEnabled {
            scheduleNotification(for: scheduledSessions[index])
        } else {
            cancelNotification(for: scheduledSessions[index])
        }
    }

    private func loadScheduledSessions() {
        if let data = userDefaults.data(forKey: scheduledKey),
           let sessions = try? JSONDecoder().decode([ScheduledSession].self, from: data) {
            scheduledSessions = sessions
        }
    }

    private func saveScheduledSessions() {
        if let data = try? JSONEncoder().encode(scheduledSessions) {
            userDefaults.set(data, forKey: scheduledKey)
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleNotification(for session: ScheduledSession) {
        let content = UNMutableNotificationContent()
        content.title = "NeuroCore"
        content.body = "Time for your \(session.modeName) session"
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: session.time)

        if session.repeatDays.isEmpty {
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: session.id.uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        } else {
            for day in session.repeatDays {
                var dayComponents = components
                dayComponents.weekday = day
                let trigger = UNCalendarNotificationTrigger(dateMatching: dayComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "\(session.id.uuidString)-\(day)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    private func cancelNotification(for session: ScheduledSession) {
        var identifiers = [session.id.uuidString]
        for day in 1...7 {
            identifiers.append("\(session.id.uuidString)-\(day)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Streak Tracking

    private func loadStreakData() {
        currentStreak = userDefaults.integer(forKey: streakKey)
        longestStreak = userDefaults.integer(forKey: longestStreakKey)
        checkStreakContinuity()
    }

    private func checkStreakContinuity() {
        guard let lastDateData = userDefaults.object(forKey: lastSessionDateKey) as? Date else {
            currentStreak = 0
            return
        }

        let calendar = Calendar.current
        let daysSinceLastSession = calendar.dateComponents([.day], from: lastDateData, to: Date()).day ?? 0

        if daysSinceLastSession > 1 {
            currentStreak = 0
            saveStreakData()
        }
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = userDefaults.object(forKey: lastSessionDateKey) as? Date {
            let lastDay = calendar.startOfDay(for: lastDate)

            if lastDay == today {
                return
            } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                      calendar.isDate(lastDay, inSameDayAs: yesterday) {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        userDefaults.set(today, forKey: lastSessionDateKey)
        saveStreakData()
    }

    private func saveStreakData() {
        userDefaults.set(currentStreak, forKey: streakKey)
        userDefaults.set(longestStreak, forKey: longestStreakKey)
    }

    // MARK: - Extended Runtime

    private func requestExtendedRuntime() {
        extendedRuntimeSession = WKExtendedRuntimeSession()
        extendedRuntimeSession?.delegate = ExtendedRuntimeDelegate.shared

        // Handle session expiring (30 min limit approaching)
        ExtendedRuntimeDelegate.shared.onSessionExpiring = { [weak self] in
            // Session will expire soon - haptics will only work in foreground after this
            self?.objectWillChange.send()
        }

        extendedRuntimeSession?.start()
    }

    private func endExtendedRuntime() {
        extendedRuntimeSession?.invalidate()
        extendedRuntimeSession = nil
    }

    // MARK: - Persistence

    private func loadUserPreferences() {
        if let savedIntensity = userDefaults.object(forKey: intensityKey) as? Double {
            intensity = savedIntensity
            currentAdaptiveIntensity = savedIntensity
        }
        if let savedDuration = userDefaults.object(forKey: durationKey) as? Double {
            duration = savedDuration
        }
        if let savedAdaptive = userDefaults.object(forKey: adaptiveModeKey) as? Bool {
            adaptiveModeEnabled = savedAdaptive
        }
    }

    private func saveUserPreferences() {
        userDefaults.set(intensity, forKey: intensityKey)
        userDefaults.set(duration, forKey: durationKey)
        userDefaults.set(adaptiveModeEnabled, forKey: adaptiveModeKey)
    }

    func toggleAdaptiveMode() {
        adaptiveModeEnabled.toggle()
        saveUserPreferences()

        if isSessionActive {
            if adaptiveModeEnabled {
                biometricMonitor.startMonitoring()
            } else {
                biometricMonitor.stopMonitoring()
                currentAdaptiveIntensity = intensity
                hapticEngine.updateIntensity(intensity)
            }
        }
    }

    var effectiveIntensity: Double {
        adaptiveModeEnabled ? currentAdaptiveIntensity : intensity
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

    // MARK: - HealthKit

    private func setupHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        var typesToRead: Set<HKSampleType> = []
        if let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            typesToRead.insert(hrvType)
        }
        if let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            typesToRead.insert(hrType)
        }

        guard !typesToRead.isEmpty else { return }
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { _, _ in }
    }

    func fetchRecentHRV(completion: @escaping (Double?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(nil)
            return
        }

        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion(nil)
            return
        }
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

    // MARK: - Statistics

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

    func averageSessionDuration(last days: Int = 7) -> TimeInterval {
        let count = sessionsCount(last: days)
        guard count > 0 else { return 0 }
        return totalSessionTime(last: days) / Double(count)
    }

    func mostUsedMode(last days: Int = 7) -> String? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentModes = recentSessions
            .filter { $0.completedAt >= cutoff }
            .map { $0.mode }

        let counts = recentModes.reduce(into: [:]) { $0[$1, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Supporting Types

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

struct ScheduledSession: Codable, Identifiable {
    let id: UUID
    let modeName: String
    let time: Date
    let repeatDays: Set<Int>
    var isEnabled: Bool

    init(modeName: String, time: Date, repeatDays: Set<Int>, isEnabled: Bool) {
        self.id = UUID()
        self.modeName = modeName
        self.time = time
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    var repeatDescription: String {
        if repeatDays.isEmpty {
            return "Once"
        }

        let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sortedDays = repeatDays.sorted()

        if sortedDays == [1, 2, 3, 4, 5, 6, 7] {
            return "Every day"
        } else if sortedDays == [2, 3, 4, 5, 6] {
            return "Weekdays"
        } else if sortedDays == [1, 7] {
            return "Weekends"
        }

        return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
    }
}

// MARK: - Extended Runtime Delegate

/// Handles watchOS extended runtime session lifecycle.
///
/// ## Important Limitation:
/// watchOS limits self-care extended runtime sessions to approximately 30 minutes.
/// After this time, the session will be invalidated and haptics will stop.
/// For longer sessions, haptics will only work while the app is in the foreground.
///
class ExtendedRuntimeDelegate: NSObject, WKExtendedRuntimeSessionDelegate {
    static let shared = ExtendedRuntimeDelegate()

    var onSessionExpiring: (() -> Void)?
    var onSessionInvalidated: ((WKExtendedRuntimeSessionInvalidationReason) -> Void)?

    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        DispatchQueue.main.async {
            self.onSessionInvalidated?(reason)
        }

        // Log the reason for debugging
        switch reason {
        case .none:
            print("Extended runtime ended normally")
        case .sessionInProgress:
            print("Extended runtime: another session in progress")
        case .error:
            print("Extended runtime error: \(error?.localizedDescription ?? "unknown")")
        case .expired:
            print("Extended runtime expired (30 min limit reached)")
        case .resignedFrontmost:
            print("Extended runtime: app resigned frontmost")
        case .insufficientlyActive:
            print("Extended runtime: insufficiently active")
        @unknown default:
            print("Extended runtime ended: unknown reason")
        }
    }

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended runtime session started - haptics enabled in background")
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        // Notify user that background haptics are about to stop
        DispatchQueue.main.async {
            WKInterfaceDevice.current().play(.notification)
            self.onSessionExpiring?()
        }
        print("Extended runtime expiring soon - haptics will stop in background")
    }
}
