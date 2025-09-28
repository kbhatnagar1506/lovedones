//
//  HealthKitManager.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/28/25.
//

import Foundation
import HealthKit
import SwiftUI

// MARK: - Health Data Models
struct HealthData: Codable {
    let steps: Int
    let heartRate: Double?
    let sleepHours: Double?
    let bloodPressure: BloodPressureReading?
    var medications: [Medication]
    let lastUpdated: Date
}

struct BloodPressureReading: Codable {
    let systolic: Int
    let diastolic: Int
    let timestamp: Date
}

struct Medication: Codable, Identifiable {
    let id = UUID()
    let name: String
    let dosage: String
    let frequency: String
    let timeOfDay: String
    let isActive: Bool
    let lastTaken: Date?
}

// MARK: - HealthKit Manager
class HealthKitManager: ObservableObject {
    @Published var healthData = HealthData(
        steps: 0,
        heartRate: nil,
        sleepHours: nil,
        bloodPressure: nil,
        medications: [],
        lastUpdated: Date()
    )
    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let healthStore = HKHealthStore()
    
    // HealthKit types we want to read
    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
        HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    ]
    
    init() {
        checkHealthKitAvailability()
    }
    
    private func checkHealthKitAvailability() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit is not available on this device"
            return
        }
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit is not available on this device"
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if let error = error {
                    self?.errorMessage = "HealthKit authorization failed: \(error.localizedDescription)"
                } else if success {
                    self?.loadHealthData()
                }
            }
        }
    }
    
    func loadHealthData() {
        isLoading = true
        errorMessage = nil
        
        let group = DispatchGroup()
        var steps = 0
        var heartRate: Double?
        var sleepHours: Double?
        var bloodPressure: BloodPressureReading?
        
        // Load steps
        group.enter()
        loadSteps { result in
            if case .success(let value) = result {
                steps = value
            }
            group.leave()
        }
        
        // Load heart rate
        group.enter()
        loadHeartRate { result in
            if case .success(let value) = result {
                heartRate = value
            }
            group.leave()
        }
        
        // Load sleep data
        group.enter()
        loadSleepData { result in
            if case .success(let value) = result {
                sleepHours = value
            }
            group.leave()
        }
        
        // Load blood pressure
        group.enter()
        loadBloodPressure { result in
            if case .success(let value) = result {
                bloodPressure = value
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.healthData = HealthData(
                steps: steps,
                heartRate: heartRate,
                sleepHours: sleepHours,
                bloodPressure: bloodPressure,
                medications: self.healthData.medications, // Keep existing medications
                lastUpdated: Date()
            )
            self.isLoading = false
        }
    }
    
    private func loadSteps(completion: @escaping (Result<Int, Error>) -> Void) {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(.failure(HealthKitError.invalidType))
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            completion(.success(Int(steps)))
        }
        
        healthStore.execute(query)
    }
    
    private func loadHeartRate(completion: @escaping (Result<Double, Error>) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(.failure(HealthKitError.invalidType))
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(.success(0))
                return
            }
            
            let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            completion(.success(heartRate))
        }
        
        healthStore.execute(query)
    }
    
    private func loadSleepData(completion: @escaping (Result<Double, Error>) -> Void) {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(.failure(HealthKitError.invalidType))
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now.addingTimeInterval(-86400)) // Yesterday
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 0, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let samples = samples as? [HKCategorySample] else {
                completion(.success(0))
                return
            }
            
            var totalSleepHours: Double = 0
            for sample in samples {
                if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    totalSleepHours += duration / 3600 // Convert to hours
                }
            }
            
            completion(.success(totalSleepHours))
        }
        
        healthStore.execute(query)
    }
    
    private func loadBloodPressure(completion: @escaping (Result<BloodPressureReading?, Error>) -> Void) {
        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            completion(.failure(HealthKitError.invalidType))
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfWeek, end: now, options: .strictStartDate)
        
        let group = DispatchGroup()
        var systolic: Int?
        var diastolic: Int?
        var timestamp: Date?
        
        // Load systolic
        group.enter()
        let systolicQuery = HKSampleQuery(sampleType: systolicType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
            if let sample = samples?.first as? HKQuantitySample {
                systolic = Int(sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury()))
                timestamp = sample.startDate
            }
            group.leave()
        }
        healthStore.execute(systolicQuery)
        
        // Load diastolic
        group.enter()
        let diastolicQuery = HKSampleQuery(sampleType: diastolicType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
            if let sample = samples?.first as? HKQuantitySample {
                diastolic = Int(sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury()))
            }
            group.leave()
        }
        healthStore.execute(diastolicQuery)
        
        group.notify(queue: .main) {
            if let systolic = systolic, let diastolic = diastolic, let timestamp = timestamp {
                completion(.success(BloodPressureReading(systolic: systolic, diastolic: diastolic, timestamp: timestamp)))
            } else {
                completion(.success(nil))
            }
        }
    }
    
    func addMedication(_ medication: Medication) {
        healthData.medications.append(medication)
    }
    
    func updateMedication(_ medication: Medication) {
        if let index = healthData.medications.firstIndex(where: { $0.id == medication.id }) {
            healthData.medications[index] = medication
        }
    }
    
    func removeMedication(_ medication: Medication) {
        healthData.medications.removeAll { $0.id == medication.id }
    }
}

enum HealthKitError: Error {
    case invalidType
    case authorizationDenied
    case dataNotAvailable
}

// MARK: - Health Data Extensions
extension HealthData {
    var stepsGoal: Int { 10000 }
    var stepsProgress: Double { min(Double(steps) / Double(stepsGoal), 1.0) }
    
    var heartRateStatus: String {
        guard let heartRate = heartRate else { return "No data" }
        if heartRate < 60 { return "Low" }
        else if heartRate > 100 { return "High" }
        else { return "Normal" }
    }
    
    var sleepStatus: String {
        guard let sleepHours = sleepHours else { return "No data" }
        if sleepHours < 6 { return "Insufficient" }
        else if sleepHours > 9 { return "Excessive" }
        else { return "Good" }
    }
    
    var bloodPressureStatus: String {
        guard let bp = bloodPressure else { return "No data" }
        if bp.systolic < 90 || bp.diastolic < 60 { return "Low" }
        else if bp.systolic > 140 || bp.diastolic > 90 { return "High" }
        else { return "Normal" }
    }
}
