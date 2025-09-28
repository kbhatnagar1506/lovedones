//
//  HealthTracker.swift
//  LovedOnes
//
//  Comprehensive health tracking for Alzheimer's patients
//

import Foundation
import SwiftUI
import HealthKit

class HealthTracker: ObservableObject {
    @Published var todayMoodScore: Int = 7
    @Published var memoryScore: Int = 75
    @Published var sleepScore: Int = 8
    @Published var medicationCompliance: Int = 95
    @Published var todaysActivities: [Activity] = []
    @Published var recentAlerts: [AlertItem] = []
    @Published var cognitiveAssessments: [CognitiveAssessment] = []
    @Published var medicationHistory: [MedicationEntry] = []
    @Published var sleepData: [SleepEntry] = []
    @Published var moodHistory: [MoodEntry] = []
    @Published var wanderingEvents: [WanderingEvent] = []
    @Published var speechAnalysis: [SpeechAnalysis] = []
    
    init() {
        loadSampleData()
        startPeriodicUpdates()
    }
    
    // MARK: - Data Synchronization
    
    func syncWithPatientData() {
        // This would sync with the patient's actual health data
        // For now, we'll simulate some realistic updates
        DispatchQueue.main.async {
            // Simulate slight variations in health metrics
            self.todayMoodScore = max(1, min(10, self.todayMoodScore + Int.random(in: -1...1)))
            self.memoryScore = max(0, min(100, self.memoryScore + Int.random(in: -2...2)))
            self.sleepScore = max(1, min(10, self.sleepScore + Int.random(in: -1...1)))
            self.medicationCompliance = max(0, min(100, self.medicationCompliance + Int.random(in: -1...1)))
            
            // Update trends
            self.updateTrends()
        }
    }
    
    private func updateTrends() {
        // This would update the trend calculations based on new data
        // For now, we'll just trigger a UI update
        objectWillChange.send()
    }
    
    // MARK: - Computed Properties
    
    var moodTrend: String {
        let recentMoods = moodHistory.suffix(7).map { $0.score }
        let average = recentMoods.reduce(0, +) / max(recentMoods.count, 1)
        let current = todayMoodScore
        
        if current > average + 1 {
            return "↗️ Improving"
        } else if current < average - 1 {
            return "↘️ Declining"
        } else {
            return "→ Stable"
        }
    }
    
    var memoryTrend: String {
        let recentScores = cognitiveAssessments.suffix(7).map { $0.memoryScore }
        let average = recentScores.reduce(0, +) / max(recentScores.count, 1)
        let current = memoryScore
        
        if current > average + 5 {
            return "↗️ Improving"
        } else if current < average - 5 {
            return "↘️ Declining"
        } else {
            return "→ Stable"
        }
    }
    
    var moodColor: Color {
        switch todayMoodScore {
        case 8...10: return .green
        case 6...7: return .yellow
        case 4...5: return .orange
        default: return .red
        }
    }
    
    var memoryColor: Color {
        switch memoryScore {
        case 80...100: return .green
        case 60...79: return .yellow
        case 40...59: return .orange
        default: return .red
        }
    }
    
    var sleepColor: Color {
        switch sleepScore {
        case 8...10: return .green
        case 6...7: return .yellow
        case 4...5: return .orange
        default: return .red
        }
    }
    
    var medicationColor: Color {
        switch medicationCompliance {
        case 90...100: return .green
        case 70...89: return .yellow
        case 50...69: return .orange
        default: return .red
        }
    }
    
    // MARK: - Data Loading
    
    private func loadSampleData() {
        // Today's Activities
        todaysActivities = [
            Activity(title: "Morning Medication", time: "8:00 AM", icon: "pills.fill", color: .blue, isCompleted: true),
            Activity(title: "Memory Game", time: "10:00 AM", icon: "brain.head.profile", color: .purple, isCompleted: true),
            Activity(title: "Physical Exercise", time: "2:00 PM", icon: "figure.walk", color: .green, isCompleted: false),
            Activity(title: "Evening Medication", time: "8:00 PM", icon: "pills.fill", color: .blue, isCompleted: false),
            Activity(title: "Bedtime Routine", time: "9:30 PM", icon: "moon.fill", color: .indigo, isCompleted: false)
        ]
        
        // Recent Alerts
        recentAlerts = [
            AlertItem(title: "Medication Reminder", message: "Evening medication due in 30 minutes", time: "2 hours ago", icon: "bell.fill", color: .orange),
            AlertItem(title: "Sleep Pattern Alert", message: "Unusual sleep pattern detected", time: "1 day ago", icon: "moon.fill", color: .blue),
            AlertItem(title: "Memory Assessment", message: "Weekly memory test completed", time: "2 days ago", icon: "brain.head.profile", color: .purple)
        ]
        
        // Cognitive Assessments
        cognitiveAssessments = [
            CognitiveAssessment(date: Date().addingTimeInterval(-86400), memoryScore: 78, attentionScore: 72, languageScore: 85, executiveScore: 70),
            CognitiveAssessment(date: Date().addingTimeInterval(-172800), memoryScore: 75, attentionScore: 70, languageScore: 82, executiveScore: 68),
            CognitiveAssessment(date: Date().addingTimeInterval(-259200), memoryScore: 80, attentionScore: 75, languageScore: 88, executiveScore: 72)
        ]
        
        // Medication History
        medicationHistory = [
            MedicationEntry(name: "Donepezil", dosage: "5mg", time: "8:00 AM", taken: true, date: Date()),
            MedicationEntry(name: "Memantine", dosage: "10mg", time: "8:00 PM", taken: false, date: Date()),
            MedicationEntry(name: "Vitamin E", dosage: "400 IU", time: "12:00 PM", taken: true, date: Date())
        ]
        
        // Sleep Data
        sleepData = [
            SleepEntry(date: Date().addingTimeInterval(-86400), hours: 7.5, quality: 8, deepSleep: 1.5, remSleep: 1.2),
            SleepEntry(date: Date().addingTimeInterval(-172800), hours: 6.8, quality: 7, deepSleep: 1.2, remSleep: 1.0),
            SleepEntry(date: Date().addingTimeInterval(-259200), hours: 8.2, quality: 9, deepSleep: 1.8, remSleep: 1.5)
        ]
        
        // Mood History
        moodHistory = [
            MoodEntry(date: Date().addingTimeInterval(-86400), score: 7, notes: "Good day, engaged in activities"),
            MoodEntry(date: Date().addingTimeInterval(-172800), score: 6, notes: "Slightly confused in the afternoon"),
            MoodEntry(date: Date().addingTimeInterval(-259200), score: 8, notes: "Very positive, remembered family names")
        ]
        
        // Wandering Events
        wanderingEvents = [
            WanderingEvent(date: Date().addingTimeInterval(-3600), location: "Garden", duration: 15, triggered: false),
            WanderingEvent(date: Date().addingTimeInterval(-86400), location: "Neighborhood", duration: 30, triggered: true),
            WanderingEvent(date: Date().addingTimeInterval(-172800), location: "Park", duration: 45, triggered: false)
        ]
        
        // Speech Analysis
        speechAnalysis = [
            SpeechAnalysis(date: Date().addingTimeInterval(-3600), clarity: 85, wordCount: 120, repetitionRate: 0.15, confusionIndicators: 2),
            SpeechAnalysis(date: Date().addingTimeInterval(-86400), clarity: 78, wordCount: 95, repetitionRate: 0.22, confusionIndicators: 4),
            SpeechAnalysis(date: Date().addingTimeInterval(-172800), clarity: 82, wordCount: 110, repetitionRate: 0.18, confusionIndicators: 3)
        ]
    }
    
    private func startPeriodicUpdates() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.updateRealTimeData()
        }
    }
    
    private func updateRealTimeData() {
        // Simulate real-time updates
        DispatchQueue.main.async {
            // Update mood score based on recent activities
            if self.todaysActivities.filter({ $0.isCompleted }).count > 3 {
                self.todayMoodScore = min(10, self.todayMoodScore + 1)
            }
            
            // Update memory score based on cognitive assessments
            if let latestAssessment = self.cognitiveAssessments.first {
                self.memoryScore = latestAssessment.memoryScore
            }
            
            // Update sleep score based on recent sleep data
            if let latestSleep = self.sleepData.first {
                self.sleepScore = latestSleep.quality
            }
        }
    }
    
    // MARK: - Health Data Methods
    
    func addMoodEntry(score: Int, notes: String) {
        let newEntry = MoodEntry(date: Date(), score: score, notes: notes)
        moodHistory.insert(newEntry, at: 0)
        todayMoodScore = score
        
        // Limit history to last 30 days
        if moodHistory.count > 30 {
            moodHistory = Array(moodHistory.prefix(30))
        }
    }
    
    func addCognitiveAssessment(memory: Int, attention: Int, language: Int, executive: Int) {
        let newAssessment = CognitiveAssessment(
            date: Date(),
            memoryScore: memory,
            attentionScore: attention,
            languageScore: language,
            executiveScore: executive
        )
        cognitiveAssessments.insert(newAssessment, at: 0)
        memoryScore = memory
        
        // Limit history to last 30 assessments
        if cognitiveAssessments.count > 30 {
            cognitiveAssessments = Array(cognitiveAssessments.prefix(30))
        }
    }
    
    func addWanderingEvent(location: String, duration: Int, triggered: Bool) {
        let newEvent = WanderingEvent(
            date: Date(),
            location: location,
            duration: duration,
            triggered: triggered
        )
        wanderingEvents.insert(newEvent, at: 0)
        
        // Limit history to last 50 events
        if wanderingEvents.count > 50 {
            wanderingEvents = Array(wanderingEvents.prefix(50))
        }
    }
    
    func addSpeechAnalysis(clarity: Int, wordCount: Int, repetitionRate: Double, confusionIndicators: Int) {
        let newAnalysis = SpeechAnalysis(
            date: Date(),
            clarity: clarity,
            wordCount: wordCount,
            repetitionRate: repetitionRate,
            confusionIndicators: confusionIndicators
        )
        speechAnalysis.insert(newAnalysis, at: 0)
        
        // Limit history to last 50 analyses
        if speechAnalysis.count > 50 {
            speechAnalysis = Array(speechAnalysis.prefix(50))
        }
    }
    
    func markActivityCompleted(_ activityId: UUID) {
        if let index = todaysActivities.firstIndex(where: { $0.id == activityId }) {
            todaysActivities[index] = Activity(
                title: todaysActivities[index].title,
                time: todaysActivities[index].time,
                icon: todaysActivities[index].icon,
                color: todaysActivities[index].color,
                isCompleted: true
            )
        }
    }
    
    func addAlert(_ alert: AlertItem) {
        recentAlerts.insert(alert, at: 0)
        
        // Limit to last 20 alerts
        if recentAlerts.count > 20 {
            recentAlerts = Array(recentAlerts.prefix(20))
        }
    }
}

// MARK: - Data Models

struct CognitiveAssessment: Identifiable {
    let id = UUID()
    let date: Date
    let memoryScore: Int
    let attentionScore: Int
    let languageScore: Int
    let executiveScore: Int
    
    var overallScore: Int {
        (memoryScore + attentionScore + languageScore + executiveScore) / 4
    }
}

struct MedicationEntry: Identifiable {
    let id = UUID()
    let name: String
    let dosage: String
    let time: String
    let taken: Bool
    let date: Date
}

struct SleepEntry: Identifiable {
    let id = UUID()
    let date: Date
    let hours: Double
    let quality: Int
    let deepSleep: Double
    let remSleep: Double
}

struct MoodEntry: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
    let notes: String
}

struct WanderingEvent: Identifiable {
    let id = UUID()
    let date: Date
    let location: String
    let duration: Int
    let triggered: Bool
}

struct SpeechAnalysis: Identifiable {
    let id = UUID()
    let date: Date
    let clarity: Int
    let wordCount: Int
    let repetitionRate: Double
    let confusionIndicators: Int
}
