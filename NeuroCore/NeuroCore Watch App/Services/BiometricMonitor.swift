import Foundation
import HealthKit
import Combine
import SwiftUI

class BiometricMonitor: ObservableObject {
    static let shared = BiometricMonitor()

    @Published var currentHeartRate: Double = 0
    @Published var currentHRV: Double = 0
    @Published var stressLevel: StressLevel = .unknown
    @Published var isMonitoring = false
    @Published var adaptiveIntensityAdjustment: Double = 0

    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var hrvQuery: HKAnchoredObjectQuery?
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    private var baselineHRV: Double = 50
    private var baselineHR: Double = 70
    private var recentHRVReadings: [Double] = []
    private var recentHRReadings: [Double] = []

    enum StressLevel: String {
        case low = "Relaxed"
        case moderate = "Moderate"
        case high = "Stressed"
        case veryHigh = "Very Stressed"
        case unknown = "Measuring..."

        var color: Color {
            switch self {
            case .low: return .green
            case .moderate: return .yellow
            case .high: return .orange
            case .veryHigh: return .red
            case .unknown: return .gray
            }
        }

        var icon: String {
            switch self {
            case .low: return "leaf.fill"
            case .moderate: return "circle.fill"
            case .high: return "exclamationmark.triangle.fill"
            case .veryHigh: return "bolt.heart.fill"
            case .unknown: return "waveform.path.ecg"
            }
        }

        var intensityMultiplier: Double {
            switch self {
            case .low: return 0.8
            case .moderate: return 1.0
            case .high: return 1.15
            case .veryHigh: return 1.3
            case .unknown: return 1.0
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

    init() {
        loadBaselines()
    }

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard isAvailable else {
            completion(false)
            return
        }

        var typesToRead: Set<HKObjectType> = []
        if let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            typesToRead.insert(hrType)
        }
        if let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            typesToRead.insert(hrvType)
        }
        if let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            typesToRead.insert(rhrType)
        }

        let typesToShare: Set<HKSampleType> = [
            HKQuantityType.workoutType()
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    func startMonitoring() {
        guard isAvailable, !isMonitoring else { return }

        requestAuthorization { [weak self] authorized in
            guard authorized else { return }
            self?.startWorkoutSession()
            self?.startHeartRateQuery()
            self?.startHRVQuery()
            self?.isMonitoring = true
        }
    }

    func stopMonitoring() {
        stopHeartRateQuery()
        stopHRVQuery()
        stopWorkoutSession()
        isMonitoring = false
        stressLevel = .unknown
        adaptiveIntensityAdjustment = 0
    }

    private func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .indoor

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()

            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { _, _ in }
        } catch {
            print("Failed to start workout session: \(error)")
        }
    }

    private func stopWorkoutSession() {
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { _, _ in }
        workoutBuilder?.finishWorkout { _, _ in }
        workoutSession = nil
        workoutBuilder = nil
    }

    private func startHeartRateQuery() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let predicate = HKQuery.predicateForSamples(
            withStart: Date(),
            end: nil,
            options: .strictStartDate
        )

        heartRateQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        heartRateQuery?.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        if let query = heartRateQuery {
            healthStore.execute(query)
        }
    }

    private func stopHeartRateQuery() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
    }

    private func startHRVQuery() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }

        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .hour, value: -24, to: Date()),
            end: nil,
            options: .strictStartDate
        )

        hrvQuery = HKAnchoredObjectQuery(
            type: hrvType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHRVSamples(samples)
        }

        hrvQuery?.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHRVSamples(samples)
        }

        if let query = hrvQuery {
            healthStore.execute(query)
        }
    }

    private func stopHRVQuery() {
        if let query = hrvQuery {
            healthStore.stop(query)
            hrvQuery = nil
        }
    }

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else { return }

        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())

        for sample in samples {
            let hr = sample.quantity.doubleValue(for: heartRateUnit)
            recentHRReadings.append(hr)

            if recentHRReadings.count > 10 {
                recentHRReadings.removeFirst()
            }
        }

        if let latestHR = samples.last?.quantity.doubleValue(for: heartRateUnit) {
            DispatchQueue.main.async { [weak self] in
                self?.currentHeartRate = latestHR
                self?.updateStressLevel()
            }
        }
    }

    private func processHRVSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else { return }

        let hrvUnit = HKUnit.secondUnit(with: .milli)

        for sample in samples {
            let hrv = sample.quantity.doubleValue(for: hrvUnit)
            recentHRVReadings.append(hrv)

            if recentHRVReadings.count > 5 {
                recentHRVReadings.removeFirst()
            }
        }

        if let latestHRV = samples.last?.quantity.doubleValue(for: hrvUnit) {
            DispatchQueue.main.async { [weak self] in
                self?.currentHRV = latestHRV
                self?.updateStressLevel()
            }
        }
    }

    private func updateStressLevel() {
        let hrvScore = calculateHRVScore()
        let hrScore = calculateHRScore()

        let combinedScore = (hrvScore * 0.6) + (hrScore * 0.4)

        let newStressLevel: StressLevel
        switch combinedScore {
        case ..<25:
            newStressLevel = .low
        case 25..<50:
            newStressLevel = .moderate
        case 50..<75:
            newStressLevel = .high
        default:
            newStressLevel = .veryHigh
        }

        stressLevel = newStressLevel
        adaptiveIntensityAdjustment = calculateAdaptiveAdjustment()
    }

    private func calculateHRVScore() -> Double {
        guard !recentHRVReadings.isEmpty else { return 50 }

        let avgHRV = recentHRVReadings.reduce(0, +) / Double(recentHRVReadings.count)
        let hrvRatio = avgHRV / baselineHRV

        if hrvRatio >= 1.2 {
            return 10
        } else if hrvRatio >= 1.0 {
            return 25
        } else if hrvRatio >= 0.8 {
            return 50
        } else if hrvRatio >= 0.6 {
            return 75
        } else {
            return 90
        }
    }

    private func calculateHRScore() -> Double {
        guard !recentHRReadings.isEmpty else { return 50 }

        let avgHR = recentHRReadings.reduce(0, +) / Double(recentHRReadings.count)
        let hrElevation = avgHR - baselineHR

        if hrElevation <= 0 {
            return 10
        } else if hrElevation <= 10 {
            return 30
        } else if hrElevation <= 20 {
            return 50
        } else if hrElevation <= 35 {
            return 70
        } else {
            return 90
        }
    }

    private func calculateAdaptiveAdjustment() -> Double {
        switch stressLevel {
        case .low:
            return -0.1
        case .moderate:
            return 0
        case .high:
            return 0.1
        case .veryHigh:
            return 0.2
        case .unknown:
            return 0
        }
    }

    func getAdaptiveIntensity(baseIntensity: Double, mode: VibeMode) -> Double {
        let adjusted = baseIntensity + adaptiveIntensityAdjustment

        return min(mode.maxIntensity, max(mode.minIntensity, adjusted))
    }

    func getRecommendedMode() -> VibrationPattern? {
        switch stressLevel {
        case .veryHigh:
            return .calm
        case .high:
            return .unwind
        case .moderate:
            return nil
        case .low:
            return nil
        case .unknown:
            return nil
        }
    }

    private func loadBaselines() {
        fetchRestingHeartRate { [weak self] rhr in
            if let rhr = rhr {
                self?.baselineHR = rhr
            }
        }

        fetchBaselineHRV { [weak self] hrv in
            if let hrv = hrv {
                self?.baselineHRV = hrv
            }
        }
    }

    private func fetchRestingHeartRate(completion: @escaping (Double?) -> Void) {
        guard let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            completion(nil)
            return
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: rhrType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }

            let rhr = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            completion(rhr)
        }

        healthStore.execute(query)
    }

    private func fetchBaselineHRV(completion: @escaping (Double?) -> Void) {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion(nil)
            return
        }

        guard let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
            completion(nil)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(
            quantityType: hrvType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage
        ) { _, statistics, _ in
            guard let avg = statistics?.averageQuantity() else {
                completion(nil)
                return
            }

            let hrv = avg.doubleValue(for: HKUnit.secondUnit(with: .milli))
            completion(hrv)
        }

        healthStore.execute(query)
    }

    var stressDescription: String {
        switch stressLevel {
        case .low:
            return "Your body is relaxed. Lower intensity recommended."
        case .moderate:
            return "Normal stress levels. Standard intensity."
        case .high:
            return "Elevated stress detected. Increasing calming intensity."
        case .veryHigh:
            return "High stress detected. Maximizing calming effect."
        case .unknown:
            return "Gathering biometric data..."
        }
    }
}
