//
//  CognitiveAssessmentManager.swift
//  LovedOnes
//
//  AI-powered cognitive assessment and memory quiz system
//

import Foundation
import SwiftUI
import AVFoundation

// MARK: - 🧠 COGNITIVE ASSESSMENT MANAGER

class CognitiveAssessmentManager: ObservableObject {
    @Published var isAssessmentActive = false
    @Published var currentSession: QuizSession?
    @Published var assessmentResults: AssessmentResults?
    @Published var userProgress: UserProgress?
    
    private let apiBaseURL = "https://lovedones-app-3d38a08e2be6.herokuapp.com"
    private var session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - 🎯 QUIZ SESSION MANAGEMENT
    
    func startMemoryQuiz(difficulty: QuizDifficulty = .mixed, questionCount: Int = 8) {
        Task {
            do {
                let session = try await createQuizSession(difficulty: difficulty, questionCount: questionCount)
                await MainActor.run {
                    self.currentSession = session
                    self.isAssessmentActive = true
                }
            } catch {
                print("❌ Failed to start quiz: \(error)")
            }
        }
    }
    
    private func createQuizSession(difficulty: QuizDifficulty, questionCount: Int) async throws -> QuizSession {
        let request = QuizCreationRequest(
            userId: "user123", // In practice, get from user session
            difficultyLevel: difficulty.rawValue,
            nQuestions: questionCount
        )
        
        let result: QuizCreationResponse = try await makeAPICall(
            endpoint: "/memory/quiz/create",
            method: "POST",
            body: request
        )
        
        return result.session
    }
    
    func submitAnswer(questionId: String, selectedOptionId: String, responseTimeMs: Int) async throws -> QuizAnswerResult {
        guard let sessionId = currentSession?.sessionId else {
            throw CognitiveAssessmentError.noActiveSession
        }
        
        let request = QuizAnswerRequest(
            sessionId: sessionId,
            questionId: questionId,
            selectedOptionId: selectedOptionId,
            responseTimeMs: responseTimeMs
        )
        
        let result: QuizAnswerResponse = try await makeAPICall(
            endpoint: "/memory/quiz/submit",
            method: "POST",
            body: request
        )
        
        return result.result
    }
    
    func completeQuiz() async throws -> QuizCompletionResult {
        guard let sessionId = currentSession?.sessionId else {
            throw CognitiveAssessmentError.noActiveSession
        }
        
        let request = QuizCompletionRequest(sessionId: sessionId)
        let result: QuizCompletionResponse = try await makeAPICall(
            endpoint: "/memory/quiz/complete",
            method: "POST",
            body: request
        )
        
        await MainActor.run {
            self.assessmentResults = AssessmentResults(
                accuracy: result.results.finalMetrics.accuracy,
                avgResponseTime: result.results.finalMetrics.avgResponseTime,
                cognitiveLoad: result.results.finalMetrics.cognitiveLoad,
                insights: result.results.insights,
                recommendations: result.results.recommendations
            )
            self.isAssessmentActive = false
            self.currentSession = nil
        }
        
        return result.results
    }
    
    // MARK: - 🎤 SPEECH ANALYSIS
    
    func analyzeSpeechFeatures(_ features: SpeechFeatures) async throws -> CognitiveLoadAssessment {
        let request = SpeechAnalysisRequest(features: features)
        let result: SpeechAnalysisResponse = try await makeAPICall(
            endpoint: "/speech/analyze",
            method: "POST",
            body: request
        )
        
        return CognitiveLoadAssessment(
            loadBand: result.cognitiveLoadBand,
            confidence: result.confidence,
            timestamp: result.timestamp
        )
    }
    
    // MARK: - 📊 PROGRESS TRACKING
    
    func fetchUserProgress(userId: String) async throws -> UserProgress {
        let result: UserProgressResponse = try await makeAPICall(
            endpoint: "/memory/quiz/progress/\(userId)",
            method: "GET"
        )
        
        await MainActor.run {
            self.userProgress = result.progress
        }
        
        return result.progress
    }
    
    // MARK: - 🔧 HELPER METHODS
    
    private func makeAPICall<R: Codable>(
        endpoint: String,
        method: String
    ) async throws -> R {
        guard let url = URL(string: apiBaseURL + endpoint) else {
            throw CognitiveAssessmentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CognitiveAssessmentError.invalidResponse
        }
        
        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw CognitiveAssessmentError.apiError(httpResponse.statusCode, "Server returned error status")
        }
        
        let result = try JSONDecoder().decode(R.self, from: data)
        return result
    }
    
    // MARK: - 🤖 AI-POWERED SUMMARIES
    
    func generateAISessionSummary(sessionData: [String: Any]) async throws -> AISessionSummary {
        let request = AISessionSummaryRequest(sessionData: sessionData)
        let result: AISessionSummaryResponse = try await makeAPICall(
            endpoint: "/ai/session_summary",
            method: "POST",
            body: request
        )
        
        return result.aiSummary
    }
    
    func generateAIProgressSummary(progressData: [String: Any]) async throws -> AIProgressSummary {
        let request = AIProgressSummaryRequest(progressData: progressData)
        let result: AIProgressSummaryResponse = try await makeAPICall(
            endpoint: "/ai/progress_summary",
            method: "POST",
            body: request
        )
        
        return result.aiSummary
    }
    
    func generateAIClinicianReport(assessmentData: [String: Any]) async throws -> AIClinicianReport {
        let request = AIClinicianReportRequest(assessmentData: assessmentData)
        let result: AIClinicianReportResponse = try await makeAPICall(
            endpoint: "/ai/clinician_report",
            method: "POST",
            body: request
        )
        
        return result.aiReport
    }
    
    func generateAIFamilyInsights(familyData: [String: Any]) async throws -> AIFamilyInsights {
        let request = AIFamilyInsightsRequest(familyData: familyData)
        let result: AIFamilyInsightsResponse = try await makeAPICall(
            endpoint: "/ai/family_insights",
            method: "POST",
            body: request
        )
        
        return result.aiInsights
    }
    
    func generateAIMemoryStory(memoryItem: [String: Any], performance: [String: Any]) async throws -> String {
        let request = AIMemoryStoryRequest(memoryItem: memoryItem, performance: performance)
        let result: AIMemoryStoryResponse = try await makeAPICall(
            endpoint: "/ai/memory_story",
            method: "POST",
            body: request
        )
        
        return result.memoryStory
    }
    
    // MARK: - 🔄 SCHEDULER INTEGRATION
    
    func getNextReviewInterval(itemId: Int, difficulty: Int, loadBand: String) async throws -> ReviewInterval {
        let request = ReviewIntervalRequest(
            itemId: itemId,
            difficulty: difficulty,
            loadBand: loadBand
        )
        
        let result: ReviewIntervalResponse = try await makeAPICall(
            endpoint: "/scheduler/next_interval",
            method: "POST",
            body: request
        )
        
        return ReviewInterval(
            seconds: result.nextIntervalSeconds,
            minutes: result.nextIntervalMinutes,
            itemId: result.itemId
        )
    }
    
    func recordReviewResult(itemId: Int, correct: Bool, latencySec: Double, difficulty: Int, loadBand: String) async throws -> ItemStatistics {
        let request = ReviewResultRequest(
            itemId: itemId,
            correct: correct,
            latencySec: latencySec,
            difficulty: difficulty,
            loadBand: loadBand
        )
        
        let result: ReviewResultResponse = try await makeAPICall(
            endpoint: "/scheduler/record_result",
            method: "POST",
            body: request
        )
        
        return result.itemStatistics
    }
    
    // MARK: - 🌐 API COMMUNICATION
    
    private func makeAPICall<T: Codable, R: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil
    ) async throws -> R {
        guard let url = URL(string: apiBaseURL + endpoint) else {
            throw CognitiveAssessmentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CognitiveAssessmentError.invalidResponse
        }
        
        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CognitiveAssessmentError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        let result = try JSONDecoder().decode(R.self, from: data)
        return result
    }
}

// MARK: - 📋 DATA MODELS

struct QuizCreationRequest: Codable {
    let userId: String
    let difficultyLevel: String
    let nQuestions: Int
}

struct QuizCreationResponse: Codable {
    let success: Bool
    let session: QuizSession
}

struct UserProgressResponse: Codable {
    let success: Bool
    let progress: UserProgress
}

struct QuizSession: Codable, Identifiable {
    let sessionId: String
    let userId: String
    let createdAt: String
    let difficultyLevel: String
    let questionCount: Int
    let questions: [QuizQuestion]
    let status: String
    
    var id: String { sessionId }
}

struct QuizQuestion: Codable, Identifiable {
    let questionId: String
    let itemId: Int
    let title: String
    let description: String
    let imagePath: String
    let familyMember: String
    let difficulty: Int
    let questionType: String
    let options: [QuizOption]
    
    var id: String { questionId }
}

struct QuizOption: Codable, Identifiable {
    let optionId: String
    let text: String
    let isCorrect: Bool
    let itemId: Int
    
    var id: String { optionId }
}

struct QuizAnswerRequest: Codable {
    let sessionId: String
    let questionId: String
    let selectedOptionId: String
    let responseTimeMs: Int
}

struct QuizAnswerResponse: Codable {
    let success: Bool
    let result: QuizAnswerResult
}

struct QuizAnswerResult: Codable {
    let isCorrect: Bool
    let correctOptionId: String
    let responseTimeSec: Double
    let sessionMetrics: SessionMetrics
}

struct QuizCompletionRequest: Codable {
    let sessionId: String
}

struct QuizCompletionResponse: Codable {
    let success: Bool
    let results: QuizCompletionResult
}

struct QuizCompletionResult: Codable {
    let sessionId: String
    let finalMetrics: SessionMetrics
    let insights: [String]
    let recommendations: [String]
}

struct SessionMetrics: Codable {
    let totalQuestions: Int
    let correctAnswers: Int
    let accuracy: Double
    let avgResponseTime: Double
    let medianResponseTime: Double
    let cognitiveLoad: String
    let completionRate: Double
}

struct AssessmentResults: Equatable {
    let accuracy: Double
    let avgResponseTime: Double
    let cognitiveLoad: String
    let insights: [String]
    let recommendations: [String]
}

struct UserProgress: Codable {
    let userId: String
    let totalSessions: Int
    let avgAccuracy: Double
    let avgResponseTime: Double
    let recentAccuracy: Double
    let trend: String
    let lastSession: String?
}

struct SpeechFeatures: Codable {
    let wpm: Double
    let pauseRate: Double
    let ttr: Double
    let jitter: Double
    let articulationRate: Double
}

struct SpeechAnalysisRequest: Codable {
    let features: SpeechFeatures
}

struct SpeechAnalysisResponse: Codable {
    let cognitiveLoadBand: String
    let confidence: Double
    let timestamp: String
    let featuresAnalyzed: SpeechFeatures
}

struct CognitiveLoadAssessment {
    let loadBand: String
    let confidence: Double
    let timestamp: String
}

struct ReviewIntervalRequest: Codable {
    let itemId: Int
    let difficulty: Int
    let loadBand: String
}

struct ReviewIntervalResponse: Codable {
    let success: Bool
    let nextIntervalSeconds: Int
    let nextIntervalMinutes: Double
    let itemId: Int
}

struct ReviewInterval {
    let seconds: Int
    let minutes: Double
    let itemId: Int
}

struct ReviewResultRequest: Codable {
    let itemId: Int
    let correct: Bool
    let latencySec: Double
    let difficulty: Int
    let loadBand: String
}

struct ReviewResultResponse: Codable {
    let success: Bool
    let itemStatistics: ItemStatistics
}

struct ItemStatistics: Codable {
    let totalSessions: Int
    let accuracy: Double
    let avgLatency: Double
    let avgReward: Double
    let currentStreak: Int
}

// MARK: - 🤖 AI SUMMARY MODELS

struct AISessionSummaryRequest: Codable {
    let sessionData: [String: String]
    
    init(sessionData: [String: Any]) {
        self.sessionData = sessionData.mapValues { String(describing: $0) }
    }
}

struct AISessionSummaryResponse: Codable {
    let success: Bool
    let aiSummary: AISessionSummary
}

struct AISessionSummary: Codable {
    let summary: String
    let insights: String
    let familyRecommendations: String
    let nextSteps: String
    
    enum CodingKeys: String, CodingKey {
        case summary
        case insights
        case familyRecommendations = "family_recommendations"
        case nextSteps = "next_steps"
    }
}

struct AIProgressSummaryRequest: Codable {
    let progressData: [String: String]
    
    init(progressData: [String: Any]) {
        self.progressData = progressData.mapValues { String(describing: $0) }
    }
}

struct AIProgressSummaryResponse: Codable {
    let success: Bool
    let aiSummary: AIProgressSummary
}

struct AIProgressSummary: Codable {
    let overview: String
    let trendAnalysis: String
    let careRecommendations: String
    let healthcareGuidance: String
    
    enum CodingKeys: String, CodingKey {
        case overview
        case trendAnalysis = "trend_analysis"
        case careRecommendations = "care_recommendations"
        case healthcareGuidance = "healthcare_guidance"
    }
}

struct AIClinicianReportRequest: Codable {
    let assessmentData: [String: String]
    
    init(assessmentData: [String: Any]) {
        self.assessmentData = assessmentData.mapValues { String(describing: $0) }
    }
}

struct AIClinicianReportResponse: Codable {
    let success: Bool
    let aiReport: AIClinicianReport
}

struct AIClinicianReport: Codable {
    let executiveSummary: String
    let performanceAnalysis: String
    let clinicalRecommendations: String
    let monitoringPlan: String
    
    enum CodingKeys: String, CodingKey {
        case executiveSummary = "executive_summary"
        case performanceAnalysis = "performance_analysis"
        case clinicalRecommendations = "clinical_recommendations"
        case monitoringPlan = "monitoring_plan"
    }
}

struct AIFamilyInsightsRequest: Codable {
    let familyData: [String: String]
    
    init(familyData: [String: Any]) {
        self.familyData = familyData.mapValues { String(describing: $0) }
    }
}

struct AIFamilyInsightsResponse: Codable {
    let success: Bool
    let aiInsights: AIFamilyInsights
}

struct AIFamilyInsights: Codable {
    let resultsExplanation: String
    let dailyStrategies: String
    let communicationTips: String
    let warningSigns: String
    let supportResources: String
    
    enum CodingKeys: String, CodingKey {
        case resultsExplanation = "results_explanation"
        case dailyStrategies = "daily_strategies"
        case communicationTips = "communication_tips"
        case warningSigns = "warning_signs"
        case supportResources = "support_resources"
    }
}

struct AIMemoryStoryRequest: Codable {
    let memoryItem: [String: String]
    let performance: [String: String]
    
    init(memoryItem: [String: Any], performance: [String: Any]) {
        self.memoryItem = memoryItem.mapValues { String(describing: $0) }
        self.performance = performance.mapValues { String(describing: $0) }
    }
}

struct AIMemoryStoryResponse: Codable {
    let success: Bool
    let memoryStory: String
}

// MARK: - 🎯 ENUMS

enum QuizDifficulty: String, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case mixed = "mixed"
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .mixed: return "Mixed"
        }
    }
}

enum CognitiveAssessmentError: Error, LocalizedError {
    case noActiveSession
    case invalidURL
    case invalidResponse
    case apiError(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "No active quiz session"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid API response"
        case .apiError(let code, let message):
            return "API Error \(code): \(message)"
        }
    }
}

// MARK: - 🎨 SWIFTUI VIEWS

struct CognitiveAssessmentView: View {
    @StateObject private var assessmentManager = CognitiveAssessmentManager()
    @State private var selectedChallenge: CognitiveChallengeType? = nil
    @State private var showingResults = false
    @State private var showingVoiceChallenge = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                        
                        Text("Daily Checkpoint")
                            .font(LovedOnesDesignSystem.titleFont)
                            .fontWeight(.bold)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        
                        Text("Complete cognitive challenges to maintain mental wellness")
                            .font(LovedOnesDesignSystem.bodyFont)
                            .foregroundColor(LovedOnesDesignSystem.darkGray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Challenge Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(CognitiveChallengeType.allCases, id: \.self) { challengeType in
                            ChallengeCardView(
                                challengeType: challengeType,
                                onTap: {
                                    selectedChallenge = challengeType
                                    startChallenge(challengeType)
                                }
                            )
                        }
                        
                        // Voice Challenge Card
                        VoiceChallengeCardView(
                            onTap: {
                                showingVoiceChallenge = true
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Progress Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Progress")
                            .font(LovedOnesDesignSystem.subheadingFont)
                            .fontWeight(.semibold)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        
                        ProgressView(value: 0.3, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: LovedOnesDesignSystem.primaryRed))
                        
                        Text("3 of 7 challenges completed")
                            .font(LovedOnesDesignSystem.bodyFont)
                            .foregroundColor(LovedOnesDesignSystem.darkGray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LovedOnesDesignSystem.lightGray.opacity(0.3))
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Daily Checkpoint")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $assessmentManager.isAssessmentActive) {
            if let session = assessmentManager.currentSession {
                QuizSessionView(session: session, assessmentManager: assessmentManager)
            }
        }
        .sheet(isPresented: $showingResults) {
            if let results = assessmentManager.assessmentResults {
                AssessmentResultsView(results: results)
            }
        }
        .sheet(isPresented: $showingVoiceChallenge) {
            VoiceChallengeView()
        }
        .onChange(of: assessmentManager.assessmentResults) { results in
            if results != nil {
                showingResults = true
            }
        }
    }
    
    private func startChallenge(_ challengeType: CognitiveChallengeType) {
        switch challengeType {
        case .memory:
            assessmentManager.startMemoryQuiz(difficulty: .mixed, questionCount: 8)
        case .attention:
            assessmentManager.startMemoryQuiz(difficulty: .mixed, questionCount: 8)
        case .processing:
            assessmentManager.startMemoryQuiz(difficulty: .mixed, questionCount: 8)
        case .language:
            assessmentManager.startMemoryQuiz(difficulty: .mixed, questionCount: 8)
        case .executive:
            assessmentManager.startMemoryQuiz(difficulty: .mixed, questionCount: 8)
        case .whosWho:
            assessmentManager.startMemoryQuiz(difficulty: .mixed, questionCount: 8)
        }
    }
}

struct QuizSessionView: View {
    let session: QuizSession
    @ObservedObject var assessmentManager: CognitiveAssessmentManager
    @State private var currentQuestionIndex = 0
    @State private var selectedOptionId: String?
    @State private var startTime: Date?
    @State private var showingCompletion = false
    
    var currentQuestion: QuizQuestion {
        session.questions[currentQuestionIndex]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress
                ProgressView(value: Double(currentQuestionIndex), total: Double(session.questionCount))
                    .progressViewStyle(LinearProgressViewStyle(tint: LovedOnesDesignSystem.primaryRed))
                    .padding(.horizontal, 20)
                
                // Question
                VStack(spacing: 16) {
                    Text("Question \(currentQuestionIndex + 1) of \(session.questionCount)")
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                    
                    Text(currentQuestion.title)
                        .font(LovedOnesDesignSystem.titleFont)
                        .fontWeight(.bold)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(currentQuestion.description)
                        .font(LovedOnesDesignSystem.bodyFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                // Image placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("Family Photo")
                                .font(LovedOnesDesignSystem.captionFont)
                                .foregroundColor(.gray)
                        }
                    )
                    .padding(.horizontal, 20)
                
                // Options
                VStack(spacing: 12) {
                    ForEach(currentQuestion.options) { option in
                        Button(action: {
                            selectedOptionId = option.optionId
                        }) {
                            HStack {
                                Text(option.text)
                                    .font(LovedOnesDesignSystem.bodyFont)
                                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                                
                                Spacer()
                                
                                if selectedOptionId == option.optionId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(LovedOnesDesignSystem.primaryRed)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedOptionId == option.optionId ? 
                                          LovedOnesDesignSystem.primaryRed.opacity(0.1) : 
                                          Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedOptionId == option.optionId ? 
                                            LovedOnesDesignSystem.primaryRed : 
                                            Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentQuestionIndex > 0 {
                        Button("Previous") {
                            withAnimation {
                                currentQuestionIndex -= 1
                                selectedOptionId = nil
                            }
                        }
                        .font(LovedOnesDesignSystem.buttonFont)
                        .foregroundColor(LovedOnesDesignSystem.primaryRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(LovedOnesDesignSystem.primaryRed, lineWidth: 1)
                        )
                    }
                    
                    Button(currentQuestionIndex == session.questionCount - 1 ? "Finish" : "Next") {
                        if let selectedId = selectedOptionId {
                            submitAnswer(selectedId: selectedId)
                        }
                    }
                    .font(LovedOnesDesignSystem.buttonFont)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedOptionId != nil ? LovedOnesDesignSystem.primaryRed : Color.gray)
                    .cornerRadius(8)
                    .disabled(selectedOptionId == nil)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Memory Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
        .onAppear {
            startTime = Date()
        }
    }
    
    private func submitAnswer(selectedId: String) {
        guard let startTime = startTime else { return }
        
        let responseTime = Int(Date().timeIntervalSince(startTime) * 1000)
        
        Task {
            do {
                let result = try await assessmentManager.submitAnswer(
                    questionId: currentQuestion.questionId,
                    selectedOptionId: selectedId,
                    responseTimeMs: responseTime
                )
                
                await MainActor.run {
                    if currentQuestionIndex == session.questionCount - 1 {
                        // Last question - complete the quiz
                        Task {
                            do {
                                _ = try await assessmentManager.completeQuiz()
                            } catch {
                                print("❌ Failed to complete quiz: \(error)")
                            }
                        }
                    } else {
                        // Move to next question
                        withAnimation {
                            currentQuestionIndex += 1
                            selectedOptionId = nil
                            self.startTime = Date()
                        }
                    }
                }
            } catch {
                print("❌ Failed to submit answer: \(error)")
            }
        }
    }
}

struct AssessmentResultsView: View {
    let results: AssessmentResults
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(LovedOnesDesignSystem.successGreen)
                        
                        Text("Assessment Complete!")
                            .font(LovedOnesDesignSystem.titleFont)
                            .fontWeight(.bold)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    }
                    .padding(.top, 20)
                    
                    // Results Cards
                    VStack(spacing: 16) {
                        // Accuracy Card
                        ResultCard(
                            title: "Accuracy",
                            value: "\(Int(results.accuracy * 100))%",
                            icon: "target",
                            color: LovedOnesDesignSystem.successGreen
                        )
                        
                        // Response Time Card
                        ResultCard(
                            title: "Avg Response Time",
                            value: String(format: "%.1fs", results.avgResponseTime),
                            icon: "clock",
                            color: LovedOnesDesignSystem.infoBlue
                        )
                        
                        // Cognitive Load Card
                        ResultCard(
                            title: "Cognitive Load",
                            value: results.cognitiveLoad.capitalized,
                            icon: "brain.head.profile",
                            color: cognitiveLoadColor(results.cognitiveLoad)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Insights
                    if !results.insights.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Insights")
                                .font(LovedOnesDesignSystem.subheadingFont)
                                .fontWeight(.semibold)
                                .foregroundColor(LovedOnesDesignSystem.textPrimary)
                            
                            ForEach(results.insights, id: \.self) { insight in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(LovedOnesDesignSystem.warningOrange)
                                        .font(.system(size: 16))
                                    
                                    Text(insight)
                                        .font(LovedOnesDesignSystem.bodyFont)
                                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Recommendations
                    if !results.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommendations")
                                .font(LovedOnesDesignSystem.subheadingFont)
                                .fontWeight(.semibold)
                                .foregroundColor(LovedOnesDesignSystem.textPrimary)
                            
                            ForEach(results.recommendations, id: \.self) { recommendation in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(LovedOnesDesignSystem.primaryRed)
                                        .font(.system(size: 16))
                                    
                                    Text(recommendation)
                                        .font(LovedOnesDesignSystem.bodyFont)
                                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func cognitiveLoadColor(_ load: String) -> Color {
        switch load.lowercased() {
        case "low": return LovedOnesDesignSystem.successGreen
        case "moderate": return LovedOnesDesignSystem.warningOrange
        case "high": return LovedOnesDesignSystem.dangerRed
        default: return LovedOnesDesignSystem.mediumGray
        }
    }
}

struct ResultCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                
                Text(value)
                    .font(LovedOnesDesignSystem.titleFont)
                    .fontWeight(.bold)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
            }
            
            Spacer()
        }
        .padding(16)
                .background(LovedOnesDesignSystem.lightGray)
                .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 🧠 COGNITIVE QUIZ VIEW

struct CognitiveQuizView: View {
    @ObservedObject var assessmentManager: CognitiveAssessmentManager
    let difficulty: QuizDifficulty
    @Environment(\.dismiss) private var dismiss
    @State private var currentQuestionIndex = 0
    @State private var selectedOptionId: String?
    @State private var startTime: Date?
    @State private var showingCompletion = false
    @State private var quizCompleted = false
    
    var currentQuestion: QuizQuestion? {
        guard let session = assessmentManager.currentSession,
              currentQuestionIndex < session.questions.count else { return nil }
        return session.questions[currentQuestionIndex]
    }
    
    var progress: Double {
        guard let session = assessmentManager.currentSession else { return 0.0 }
        return Double(currentQuestionIndex) / Double(session.questions.count)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LovedOnesDesignSystem.warmGray
                    .ignoresSafeArea()
                
                if let question = currentQuestion {
                    VStack(spacing: 0) {
                        // Header with Progress
                        headerSection
                        
                        // Question Content
                        questionContent(question)
                        
                        // Answer Options
                        answerOptions(question)
                        
                        // Navigation Buttons
                        navigationButtons
                    }
                } else {
                    // Loading or Error State
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Preparing your quiz...")
                            .font(LovedOnesDesignSystem.bodyFont)
                            .foregroundColor(LovedOnesDesignSystem.darkGray)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            startQuiz()
        }
        .sheet(isPresented: $showingCompletion) {
            if let results = assessmentManager.assessmentResults {
                QuizCompletionView(results: results, onDismiss: {
                    dismiss()
                })
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(LovedOnesDesignSystem.bodyFont)
                .foregroundColor(LovedOnesDesignSystem.primaryRed)
                
                Spacer()
                
                Text("Memory Quiz")
                    .font(LovedOnesDesignSystem.headingFont)
                    .fontWeight(.semibold)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                Spacer()
                
                Text("\(currentQuestionIndex + 1)/\(assessmentManager.currentSession?.questions.count ?? 0)")
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(LovedOnesDesignSystem.darkGray)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(LovedOnesDesignSystem.lightGray)
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [LovedOnesDesignSystem.primaryRed, LovedOnesDesignSystem.secondaryRed],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Question Content
    private func questionContent(_ question: QuizQuestion) -> some View {
        VStack(spacing: 20) {
            // Question Image
            AsyncImage(url: URL(string: question.imagePath)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LovedOnesDesignSystem.lightGray)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(LovedOnesDesignSystem.mediumGray)
                    )
            }
            .frame(height: 200)
            .cornerRadius(16)
            .clipped()
            
            // Question Text
            VStack(spacing: 12) {
                Text(question.title)
                    .font(LovedOnesDesignSystem.titleFont)
                    .fontWeight(.bold)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    .multilineTextAlignment(.center)
                
                if !question.description.isEmpty {
                    Text(question.description)
                        .font(LovedOnesDesignSystem.bodyFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
    
    // MARK: - Answer Options
    private func answerOptions(_ question: QuizQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(question.options, id: \.optionId) { option in
                AnswerOptionButton(
                    option: option,
                    isSelected: selectedOptionId == option.optionId,
                    action: {
                        selectedOptionId = option.optionId
                    }
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        VStack(spacing: 16) {
            if selectedOptionId != nil {
                Button(action: submitAnswer) {
                    HStack(spacing: 12) {
                        Text(currentQuestionIndex == (assessmentManager.currentSession?.questions.count ?? 0) - 1 ? "Finish Quiz" : "Next Question")
                            .font(LovedOnesDesignSystem.buttonFont)
                            .fontWeight(.semibold)
                        
                        Image(systemName: currentQuestionIndex == (assessmentManager.currentSession?.questions.count ?? 0) - 1 ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [LovedOnesDesignSystem.primaryRed, LovedOnesDesignSystem.secondaryRed],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            Text("Take your time to think about the answer")
                .font(LovedOnesDesignSystem.captionFont)
                .foregroundColor(LovedOnesDesignSystem.darkGray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Actions
    private func startQuiz() {
        Task {
            do {
                try await assessmentManager.startMemoryQuiz(difficulty: difficulty, questionCount: 8)
            } catch {
                print("Failed to start quiz: \(error)")
            }
        }
    }
    
    private func submitAnswer() {
        guard let question = currentQuestion,
              let selectedOptionId = selectedOptionId,
              let session = assessmentManager.currentSession else { return }
        
        let responseTime = startTime?.timeIntervalSinceNow.magnitude ?? 0
        
        Task {
            do {
                let result = try await assessmentManager.submitAnswer(
                    questionId: question.questionId,
                    selectedOptionId: selectedOptionId,
                    responseTimeMs: Int(responseTime * 1000)
                )
                
                if currentQuestionIndex == session.questions.count - 1 {
                    // Quiz completed
                    await MainActor.run {
                        quizCompleted = true
                        showingCompletion = true
                    }
                } else {
                    // Move to next question
                    await MainActor.run {
                        currentQuestionIndex += 1
                        self.selectedOptionId = nil
                        startTime = Date()
                    }
                }
            } catch {
                print("Failed to submit answer: \(error)")
            }
        }
    }
}

// MARK: - Answer Option Button
struct AnswerOptionButton: View {
    let option: QuizOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Option Letter
                Text(option.optionId)
                    .font(LovedOnesDesignSystem.subheadingFont)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : LovedOnesDesignSystem.primaryRed)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? LovedOnesDesignSystem.primaryRed : LovedOnesDesignSystem.lightGray)
                    )
                
                // Option Text
                Text(option.text)
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(isSelected ? .white : LovedOnesDesignSystem.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? LovedOnesDesignSystem.primaryRed : LovedOnesDesignSystem.pureWhite)
                    .shadow(
                        color: isSelected ? LovedOnesDesignSystem.primaryRed.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isSelected ? 8 : 5,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quiz Completion View
struct QuizCompletionView: View {
    let results: AssessmentResults
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Header
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(LovedOnesDesignSystem.successGreen)
                        
                        Text("Quiz Completed!")
                            .font(LovedOnesDesignSystem.heroFont)
                            .fontWeight(.bold)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        
                        Text("Great job on completing your memory assessment")
                            .font(LovedOnesDesignSystem.bodyFont)
                            .foregroundColor(LovedOnesDesignSystem.darkGray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Results Summary
                    VStack(spacing: 16) {
                        ResultMetricCard(
                            title: "Accuracy",
                            value: "\(Int(results.accuracy * 100))%",
                            icon: "target",
                            color: LovedOnesDesignSystem.primaryRed
                        )
                        
                        ResultMetricCard(
                            title: "Response Time",
                            value: String(format: "%.1fs", results.avgResponseTime),
                            icon: "clock",
                            color: LovedOnesDesignSystem.infoBlue
                        )
                        
                        ResultMetricCard(
                            title: "Cognitive Load",
                            value: results.cognitiveLoad.capitalized,
                            icon: "brain.head.profile",
                            color: LovedOnesDesignSystem.warningOrange
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Insights
                    if !results.insights.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Insights")
                                .font(LovedOnesDesignSystem.headingFont)
                                .foregroundColor(LovedOnesDesignSystem.textPrimary)
                            
                            ForEach(results.insights, id: \.self) { insight in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.title3)
                                        .foregroundColor(LovedOnesDesignSystem.warningOrange)
                                    
                                    Text(insight)
                                        .font(LovedOnesDesignSystem.bodyFont)
                                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(20)
                        .background(LovedOnesDesignSystem.pureWhite)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button("View Detailed Results") {
                            // Show detailed results
                        }
                        .font(LovedOnesDesignSystem.buttonFont)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LovedOnesDesignSystem.primaryRed)
                        .cornerRadius(16)
                        
                        Button("Done") {
                            onDismiss()
                        }
                        .font(LovedOnesDesignSystem.bodyFont)
                        .foregroundColor(LovedOnesDesignSystem.primaryRed)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(LovedOnesDesignSystem.warmGray)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Result Metric Card
struct ResultMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(LovedOnesDesignSystem.captionFont)
                    .foregroundColor(LovedOnesDesignSystem.darkGray)
                
                Text(value)
                    .font(LovedOnesDesignSystem.titleFont)
                    .fontWeight(.bold)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(LovedOnesDesignSystem.pureWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Helper Functions
func getColorFromString(_ colorString: String) -> Color {
    switch colorString {
    case "primaryBlue": return Color.blue
    case "primaryGreen": return Color.green
    case "primaryOrange": return Color.orange
    case "primaryPurple": return Color.purple
    case "primaryRed": return Color.red
    case "primaryPink": return Color.pink
    default: return Color.gray
    }
}

// MARK: - Challenge Card View
struct ChallengeCardView: View {
    let challengeType: CognitiveChallengeType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: challengeType.icon)
                    .font(.system(size: 32))
                    .foregroundColor(getColorFromString(challengeType.color))
                
                Text(challengeType.rawValue)
                    .font(LovedOnesDesignSystem.subheadingFont)
                    .fontWeight(.semibold)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Max Score: \(challengeType.maxScore)")
                    .font(.caption)
                    .foregroundColor(LovedOnesDesignSystem.darkGray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(getColorFromString(challengeType.color).opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(getColorFromString(challengeType.color).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Voice Challenge Card View
struct VoiceChallengeCardView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.purple)
                
                Text("Voice Challenge")
                    .font(LovedOnesDesignSystem.subheadingFont)
                    .fontWeight(.semibold)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Record & Playback")
                    .font(.caption)
                    .foregroundColor(LovedOnesDesignSystem.darkGray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Voice Challenge View
struct VoiceChallengeView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var hasRecording = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("Voice Memory Challenge")
                        .font(LovedOnesDesignSystem.titleFont)
                        .fontWeight(.bold)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    
                    Text("Record yourself saying a memory, then play it back to test your recall")
                        .font(LovedOnesDesignSystem.bodyFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Recording Section
                VStack(spacing: 20) {
                    if !hasRecording {
                        // Record Button
                        Button(action: {
                            if isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }) {
                            HStack {
                                Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                                Text(isRecording ? "Stop Recording" : "Start Recording")
                            }
                            .font(LovedOnesDesignSystem.buttonFont)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isRecording ? Color.red : Color.purple)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                    } else {
                        // Playback Section
                        VStack(spacing: 16) {
                            Text("Your Recording")
                                .font(LovedOnesDesignSystem.subheadingFont)
                                .fontWeight(.semibold)
                                .foregroundColor(LovedOnesDesignSystem.textPrimary)
                            
                            HStack(spacing: 20) {
                                Button(action: {
                                    if isPlaying {
                                        audioPlayer.pause()
                                    } else {
                                        audioPlayer.play()
                                    }
                                }) {
                                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.purple)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Playback")
                                        .font(LovedOnesDesignSystem.bodyFont)
                                        .fontWeight(.semibold)
                                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                                    
                                    Text("Listen to your memory")
                                        .font(.caption)
                                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.purple.opacity(0.1))
                            )
                            
                            // New Recording Button
                            Button(action: {
                                hasRecording = false
                                isPlaying = false
                            }) {
                                Text("Record New Memory")
                                    .font(LovedOnesDesignSystem.bodyFont)
                                    .foregroundColor(.purple)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.purple, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Voice Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Complete") {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(!hasRecording)
            )
        }
    }
    
    private func startRecording() {
        audioRecorder.startRecording()
        isRecording = true
    }
    
    private func stopRecording() {
        audioRecorder.stopRecording()
        isRecording = false
        hasRecording = true
    }
}

// MARK: - Audio Recorder
class AudioRecorder: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    func startRecording() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("voice_challenge.m4a")
        recordingURL = audioFilename
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
    }
}

// MARK: - Audio Player
class AudioPlayer: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false
    
    func play() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("voice_challenge.m4a")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Could not play audio: \(error)")
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }
}

// MARK: - ScaleButtonStyle
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
