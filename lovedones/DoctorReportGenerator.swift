//
//  DoctorReportGenerator.swift
//  LovedOnes
//
//  Generate comprehensive doctor reports for Alzheimer's patients
//

import Foundation
import SwiftUI
import Charts

class DoctorReportGenerator: ObservableObject {
    @Published var generatedReports: [DoctorReport] = []
    @Published var isGenerating = false
    @Published var weeklyReport: WeeklyReport?
    
    private let healthTracker: HealthTracker
    private let locationManager: LocationManager
    private let openAIAPIKey = "YOUR_OPENAI_API_KEY_HERE"
    
    init(healthTracker: HealthTracker = HealthTracker(), locationManager: LocationManager = LocationManager()) {
        self.healthTracker = healthTracker
        self.locationManager = locationManager
        loadSampleReports()
    }
    
    func generateReport() async {
        await MainActor.run {
            isGenerating = true
        }
        
        // Simulate report generation time
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let report = createComprehensiveReport()
        
        await MainActor.run {
            generatedReports.insert(report, at: 0)
            isGenerating = false
        }
    }
    
    func generateWeeklyReport() async {
        await MainActor.run {
            isGenerating = true
        }
        
        do {
            let report = try await createWeeklyReportWithOpenAI()
            await MainActor.run {
                self.weeklyReport = report
                self.isGenerating = false
            }
        } catch {
            print("Error generating weekly report: \(error)")
            await MainActor.run {
                self.isGenerating = false
            }
        }
    }
    
    private func createWeeklyReportWithOpenAI() async throws -> WeeklyReport {
        let healthData = prepareHealthDataForOpenAI()
        
        let prompt = """
        As a medical AI assistant specializing in Alzheimer's care, please generate a comprehensive weekly health report for David, a 75-year-old Alzheimer's patient. Use the following data to create a detailed, professional medical report:

        HEALTH DATA:
        \(healthData)

        Please generate a comprehensive report that includes:
        1. Executive Summary with key findings
        2. Detailed analysis of cognitive function trends
        3. Mood and behavioral patterns
        4. Sleep quality assessment
        5. Medication adherence analysis
        6. Physical activity and mobility
        7. Safety and wandering incidents
        8. Caregiver observations and concerns
        9. Recommendations for the upcoming week
        10. Red flags or areas requiring immediate attention

        Format the response as a structured medical report with clear sections, professional language, and actionable insights. The report should be detailed enough for a doctor to understand David's condition and make informed decisions about his care.
        """
        
        let request = OpenAIRequest(
            model: "gpt-4",
            messages: [
                OpenAIMessage(role: "system", content: "You are a medical AI assistant specializing in Alzheimer's care and geriatric medicine. Generate comprehensive, professional medical reports."),
                OpenAIMessage(role: "user", content: prompt)
            ],
            maxTokens: 2000,
            temperature: 0.3
        )
        
        let report = try await callOpenAIAPI(request: request)
        return report
    }
    
    private func prepareHealthDataForOpenAI() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        return """
        PATIENT: David, 75 years old, Alzheimer's Disease
        REPORT PERIOD: \(dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date())) to \(dateFormatter.string(from: Date()))
        
        COGNITIVE METRICS:
        - Memory Score: \(healthTracker.memoryScore)% (Trend: \(healthTracker.memoryTrend))
        - Cognitive Assessments: \(healthTracker.cognitiveAssessments.count) completed this week
        - Average Assessment Score: \(calculateAverageCognitiveScore())%
        
        MOOD & BEHAVIOR:
        - Current Mood Score: \(healthTracker.todayMoodScore)/10
        - Mood Trend: \(healthTracker.moodTrend)
        - Mood History: \(healthTracker.moodHistory.count) entries this week
        
        SLEEP PATTERNS:
        - Sleep Quality Score: \(healthTracker.sleepScore)/10
        - Sleep Trend: Stable
        - Sleep Entries: \(healthTracker.sleepData.count) recorded
        
        MEDICATION COMPLIANCE:
        - Adherence Rate: \(healthTracker.medicationCompliance)%
        - Medication History: \(healthTracker.medicationHistory.count) entries
        
        SAFETY & MOBILITY:
        - Wandering Events: \(healthTracker.wanderingEvents.count) incidents
        - Location Status: \(locationManager.currentLocation ?? "Unknown")
        - Safety Alerts: \(healthTracker.recentAlerts.count) alerts
        
        ACTIVITIES & ENGAGEMENT:
        - Daily Activities: \(healthTracker.todaysActivities.count) completed
        - Activity Types: \(getActivityTypes())
        
        CAREGIVER OBSERVATIONS:
        - Recent Alerts: \(healthTracker.recentAlerts.map { $0.title }.joined(separator: ", "))
        - Speech Analysis: \(healthTracker.speechAnalysis.count) analyses completed
        """
    }
    
    private func calculateAverageCognitiveScore() -> Int {
        guard !healthTracker.cognitiveAssessments.isEmpty else { return 0 }
        let total = healthTracker.cognitiveAssessments.reduce(0) { $0 + $1.memoryScore }
        return total / healthTracker.cognitiveAssessments.count
    }
    
    private func getActivityTypes() -> String {
        let types = Set(healthTracker.todaysActivities.map { $0.title })
        return types.joined(separator: ", ")
    }
    
    private func callOpenAIAPI(request: OpenAIRequest) async throws -> WeeklyReport {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw WeeklyReportError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONEncoder().encode(request)
        urlRequest.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeeklyReportError.invalidResponse
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw WeeklyReportError.noContent
        }
        
        return WeeklyReport(
            id: UUID().uuidString,
            title: "Weekly Health Report - \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))",
            content: content,
            generatedDate: Date(),
            reportType: .weekly,
            keyFindings: extractKeyFindings(from: content),
            recommendations: extractRecommendations(from: content)
        )
    }
    
    private func extractKeyFindings(from content: String) -> [String] {
        // Simple extraction - in a real app, you'd use more sophisticated parsing
        let lines = content.components(separatedBy: .newlines)
        return lines.filter { $0.contains("•") || $0.contains("-") || $0.contains("Key") }
    }
    
    private func extractRecommendations(from content: String) -> [String] {
        // Simple extraction - in a real app, you'd use more sophisticated parsing
        let lines = content.components(separatedBy: .newlines)
        return lines.filter { $0.contains("Recommend") || $0.contains("Suggest") || $0.contains("Consider") }
    }
    
    private func createComprehensiveReport() -> DoctorReport {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        
        // Analyze trends
        let moodTrend = analyzeMoodTrend()
        let memoryTrend = analyzeMemoryTrend()
        let sleepTrend = analyzeSleepTrend()
        let wanderingTrend = analyzeWanderingTrend()
        
        // Generate insights
        let insights = generateInsights(
            moodTrend: moodTrend,
            memoryTrend: memoryTrend,
            sleepTrend: sleepTrend,
            wanderingTrend: wanderingTrend
        )
        
        // Create recommendations
        let recommendations = generateRecommendations(insights: insights)
        
        // Generate conversation cues
        let conversationCues = generateConversationCues(insights: insights)
        
        return DoctorReport(
            id: UUID(),
            date: currentDate,
            patientName: "John Smith",
            caregiverName: "Sarah Smith",
            period: "Last 30 Days",
            executiveSummary: createExecutiveSummary(insights: insights),
            topChanges: getTopChanges(insights: insights),
            cognitiveChart: createCognitiveChart(),
            moodChart: createMoodChart(),
            sleepChart: createSleepChart(),
            wanderingEvents: getWanderingEvents(),
            medicationCompliance: healthTracker.medicationCompliance,
            caregiverNotes: getCaregiverNotes(),
            insights: insights,
            recommendations: recommendations,
            conversationCues: conversationCues,
            actionItems: generateActionItems(insights: insights)
        )
    }
    
    private func analyzeMoodTrend() -> TrendAnalysis {
        let recentMoods = healthTracker.moodHistory.suffix(7).map { $0.score }
        let average = recentMoods.reduce(0, +) / max(recentMoods.count, 1)
        let trend = recentMoods.count > 1 ? (recentMoods.last! - recentMoods.first!) : 0
        
        return TrendAnalysis(
            current: healthTracker.todayMoodScore,
            average: average,
            trend: trend,
            direction: trend > 0 ? .improving : trend < 0 ? .declining : .stable
        )
    }
    
    private func analyzeMemoryTrend() -> TrendAnalysis {
        let recentScores = healthTracker.cognitiveAssessments.suffix(7).map { $0.memoryScore }
        let average = recentScores.reduce(0, +) / max(recentScores.count, 1)
        let trend = recentScores.count > 1 ? (recentScores.last! - recentScores.first!) : 0
        
        return TrendAnalysis(
            current: healthTracker.memoryScore,
            average: average,
            trend: trend,
            direction: trend > 0 ? .improving : trend < 0 ? .declining : .stable
        )
    }
    
    private func analyzeSleepTrend() -> TrendAnalysis {
        let recentSleep = healthTracker.sleepData.suffix(7).map { $0.quality }
        let average = recentSleep.reduce(0, +) / max(recentSleep.count, 1)
        let trend = recentSleep.count > 1 ? (recentSleep.last! - recentSleep.first!) : 0
        
        return TrendAnalysis(
            current: healthTracker.sleepScore,
            average: average,
            trend: trend,
            direction: trend > 0 ? .improving : trend < 0 ? .declining : .stable
        )
    }
    
    private func analyzeWanderingTrend() -> TrendAnalysis {
        let recentEvents = healthTracker.wanderingEvents.suffix(7)
        let triggeredEvents = recentEvents.filter { $0.triggered }
        let current = triggeredEvents.count
        let average = Double(triggeredEvents.count) / 7.0
        let trend = recentEvents.count > 1 ? (triggeredEvents.count - (recentEvents.count - triggeredEvents.count)) : 0
        
        return TrendAnalysis(
            current: current,
            average: Int(average),
            trend: trend,
            direction: trend > 0 ? .declining : trend < 0 ? .improving : .stable
        )
    }
    
    private func generateInsights(moodTrend: TrendAnalysis, memoryTrend: TrendAnalysis, sleepTrend: TrendAnalysis, wanderingTrend: TrendAnalysis) -> [Insight] {
        var insights: [Insight] = []
        
        // Mood insights
        if moodTrend.direction == .declining {
            insights.append(Insight(
                category: .mood,
                severity: moodTrend.trend < -2 ? .high : .medium,
                title: "Mood Decline Detected",
                description: "Patient's mood has declined by \(abs(moodTrend.trend)) points over the past week",
                recommendation: "Consider mood assessment and potential medication adjustment"
            ))
        }
        
        // Memory insights
        if memoryTrend.direction == .declining {
            insights.append(Insight(
                category: .memory,
                severity: memoryTrend.trend < -10 ? .high : .medium,
                title: "Memory Function Decline",
                description: "Memory scores have decreased by \(abs(memoryTrend.trend))% over the past week",
                recommendation: "Schedule cognitive assessment and review current medications"
            ))
        }
        
        // Sleep insights
        if sleepTrend.direction == .declining {
            insights.append(Insight(
                category: .sleep,
                severity: sleepTrend.trend < -2 ? .high : .medium,
                title: "Sleep Quality Issues",
                description: "Sleep quality has declined by \(abs(sleepTrend.trend)) points",
                recommendation: "Review sleep hygiene and consider sleep study"
            ))
        }
        
        // Wandering insights
        if wanderingTrend.direction == .declining {
            insights.append(Insight(
                category: .safety,
                severity: wanderingTrend.current > 3 ? .high : .medium,
                title: "Increased Wandering Behavior",
                description: "\(wanderingTrend.current) wandering events detected this week",
                recommendation: "Implement additional safety measures and consider medication review"
            ))
        }
        
        return insights
    }
    
    private func generateRecommendations(insights: [Insight]) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        for insight in insights {
            switch insight.category {
            case .mood:
                recommendations.append(Recommendation(
                    category: .mood,
                    priority: insight.severity == .high ? .high : .medium,
                    title: "Mood Management",
                    description: "Implement mood tracking and consider environmental modifications",
                    actionItems: [
                        "Daily mood check-ins",
                        "Increase social activities",
                        "Review medication effectiveness"
                    ]
                ))
                
            case .memory:
                recommendations.append(Recommendation(
                    category: .memory,
                    priority: insight.severity == .high ? .high : .medium,
                    title: "Cognitive Support",
                    description: "Enhance memory support strategies and activities",
                    actionItems: [
                        "Daily memory exercises",
                        "Routine establishment",
                        "Memory aids implementation"
                    ]
                ))
                
            case .sleep:
                recommendations.append(Recommendation(
                    category: .sleep,
                    priority: insight.severity == .high ? .high : .medium,
                    title: "Sleep Optimization",
                    description: "Improve sleep quality and duration",
                    actionItems: [
                        "Consistent bedtime routine",
                        "Sleep environment optimization",
                        "Limit daytime napping"
                    ]
                ))
                
            case .safety:
                recommendations.append(Recommendation(
                    category: .safety,
                    priority: insight.severity == .high ? .high : .medium,
                    title: "Safety Enhancement",
                    description: "Implement additional safety measures",
                    actionItems: [
                        "GPS tracking device",
                        "Door alarms",
                        "Safe zone monitoring"
                    ]
                ))
            }
        }
        
        return recommendations
    }
    
    private func generateConversationCues(insights: [Insight]) -> [ConversationCue] {
        var cues: [ConversationCue] = []
        
        for insight in insights {
            switch insight.category {
            case .mood:
                cues.append(ConversationCue(
                    category: .mood,
                    priority: insight.severity == .high ? .high : .medium,
                    cue: "Mention recent mood changes and emotional state",
                    context: "Patient has shown \(insight.description.lowercased())"
                ))
                
            case .memory:
                cues.append(ConversationCue(
                    category: .memory,
                    priority: insight.severity == .high ? .high : .medium,
                    cue: "Discuss memory function and cognitive changes",
                    context: "Memory scores indicate \(insight.description.lowercased())"
                ))
                
            case .sleep:
                cues.append(ConversationCue(
                    category: .sleep,
                    priority: insight.severity == .high ? .high : .medium,
                    cue: "Address sleep quality and patterns",
                    context: "Sleep data shows \(insight.description.lowercased())"
                ))
                
            case .safety:
                cues.append(ConversationCue(
                    category: .safety,
                    priority: insight.severity == .high ? .high : .medium,
                    cue: "Review safety concerns and wandering behavior",
                    context: "Safety monitoring indicates \(insight.description.lowercased())"
                ))
            }
        }
        
        return cues
    }
    
    private func createExecutiveSummary(insights: [Insight]) -> String {
        let highSeverityInsights = insights.filter { $0.severity == .high }
        let mediumSeverityInsights = insights.filter { $0.severity == .medium }
        
        var summary = "Patient shows "
        
        if highSeverityInsights.count > 0 {
            summary += "significant changes requiring immediate attention: \(highSeverityInsights.map { $0.title }.joined(separator: ", ")). "
        }
        
        if mediumSeverityInsights.count > 0 {
            summary += "Moderate concerns noted: \(mediumSeverityInsights.map { $0.title }.joined(separator: ", ")). "
        }
        
        if insights.isEmpty {
            summary += "stable condition with no significant changes detected. "
        }
        
        summary += "Overall care plan appears effective with continued monitoring recommended."
        
        return summary
    }
    
    private func getTopChanges(insights: [Insight]) -> [String] {
        return insights
            .sorted { $0.severity.rawValue > $1.severity.rawValue }
            .prefix(3)
            .map { $0.title }
    }
    
    private func createCognitiveChart() -> ChartData {
        let data = healthTracker.cognitiveAssessments.suffix(30).map { assessment in
            ChartDataPoint(
                date: assessment.date,
                value: Double(assessment.overallScore),
                label: "Cognitive Score"
            )
        }
        
        return ChartData(
            title: "Cognitive Function Over Time",
            dataPoints: data,
            yAxisLabel: "Score",
            color: .blue
        )
    }
    
    private func createMoodChart() -> ChartData {
        let data = healthTracker.moodHistory.suffix(30).map { mood in
            ChartDataPoint(
                date: mood.date,
                value: Double(mood.score),
                label: "Mood Score"
            )
        }
        
        return ChartData(
            title: "Mood Trends",
            dataPoints: data,
            yAxisLabel: "Score",
            color: .green
        )
    }
    
    private func createSleepChart() -> ChartData {
        let data = healthTracker.sleepData.suffix(30).map { sleep in
            ChartDataPoint(
                date: sleep.date,
                value: Double(sleep.quality),
                label: "Sleep Quality"
            )
        }
        
        return ChartData(
            title: "Sleep Quality Trends",
            dataPoints: data,
            yAxisLabel: "Quality Score",
            color: .purple
        )
    }
    
    private func getWanderingEvents() -> [WanderingEvent] {
        return healthTracker.wanderingEvents.suffix(10).reversed()
    }
    
    private func getCaregiverNotes() -> [String] {
        return [
            "Patient seems more confused in the afternoons",
            "Responds well to familiar music",
            "Has been asking about deceased family members",
            "Sleep pattern has changed recently",
            "More agitated during doctor visits"
        ]
    }
    
    private func generateActionItems(insights: [Insight]) -> [ActionItem] {
        var actionItems: [ActionItem] = []
        
        for insight in insights {
            switch insight.category {
            case .mood:
                actionItems.append(ActionItem(
                    title: "Schedule mood assessment",
                    priority: insight.severity == .high ? .high : .medium,
                    dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                    category: .medical
                ))
                
            case .memory:
                actionItems.append(ActionItem(
                    title: "Cognitive evaluation",
                    priority: insight.severity == .high ? .high : .medium,
                    dueDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
                    category: .medical
                ))
                
            case .sleep:
                actionItems.append(ActionItem(
                    title: "Sleep study consultation",
                    priority: insight.severity == .high ? .high : .medium,
                    dueDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
                    category: .medical
                ))
                
            case .safety:
                actionItems.append(ActionItem(
                    title: "Safety equipment installation",
                    priority: insight.severity == .high ? .high : .medium,
                    dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                    category: .safety
                ))
            }
        }
        
        return actionItems
    }
    
    private func loadSampleReports() {
        // Load sample reports for demonstration
        let sampleReport = DoctorReport(
            id: UUID(),
            date: Date().addingTimeInterval(-86400),
            patientName: "John Smith",
            caregiverName: "Sarah Smith",
            period: "Last 30 Days",
            executiveSummary: "Patient shows stable condition with minor mood fluctuations. Memory function remains consistent with current treatment plan.",
            topChanges: ["Mood fluctuations", "Sleep pattern changes", "Increased social engagement"],
            cognitiveChart: createCognitiveChart(),
            moodChart: createMoodChart(),
            sleepChart: createSleepChart(),
            wanderingEvents: getWanderingEvents(),
            medicationCompliance: 95,
            caregiverNotes: getCaregiverNotes(),
            insights: [],
            recommendations: [],
            conversationCues: [],
            actionItems: []
        )
        
        generatedReports.append(sampleReport)
    }
}

// MARK: - Data Models

struct DoctorReport: Identifiable {
    let id: UUID
    let date: Date
    let patientName: String
    let caregiverName: String
    let period: String
    let executiveSummary: String
    let topChanges: [String]
    let cognitiveChart: ChartData
    let moodChart: ChartData
    let sleepChart: ChartData
    let wanderingEvents: [WanderingEvent]
    let medicationCompliance: Int
    let caregiverNotes: [String]
    let insights: [Insight]
    let recommendations: [Recommendation]
    let conversationCues: [ConversationCue]
    let actionItems: [ActionItem]
}

struct TrendAnalysis {
    let current: Int
    let average: Int
    let trend: Int
    let direction: TrendDirection
}

enum TrendDirection {
    case improving
    case declining
    case stable
}

struct Insight: Identifiable {
    let id = UUID()
    let category: InsightCategory
    let severity: Severity
    let title: String
    let description: String
    let recommendation: String
}

enum InsightCategory {
    case mood
    case memory
    case sleep
    case safety
}

enum Severity: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
}

struct Recommendation: Identifiable {
    let id = UUID()
    let category: InsightCategory
    let priority: Priority
    let title: String
    let description: String
    let actionItems: [String]
}

enum Priority: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
}

struct ConversationCue: Identifiable {
    let id = UUID()
    let category: InsightCategory
    let priority: Priority
    let cue: String
    let context: String
}

struct ActionItem: Identifiable {
    let id = UUID()
    let title: String
    let priority: Priority
    let dueDate: Date
    let category: ActionCategory
}

enum ActionCategory {
    case medical
    case safety
    case care
    case followUp
}

struct ChartData {
    let title: String
    let dataPoints: [ChartDataPoint]
    let yAxisLabel: String
    let color: Color
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}

// MARK: - Weekly Report Data Structures

struct WeeklyReport: Identifiable {
    let id: String
    let title: String
    let content: String
    let generatedDate: Date
    let reportType: ReportType
    let keyFindings: [String]
    let recommendations: [String]
}

enum ReportType {
    case weekly
    case monthly
    case emergency
}

// MARK: - OpenAI Error Types

enum WeeklyReportError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noContent
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid OpenAI API URL"
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .noContent:
            return "No content received from OpenAI API"
        }
    }
}
