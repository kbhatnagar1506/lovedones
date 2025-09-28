//
//  AIChatbot.swift
//  LovedOnes
//
//  AI-powered caregiver support and guidance
//

import Foundation
import SwiftUI

class AIChatbot: ObservableObject {
    @Published var messages: [AIChatMessage] = []
    @Published var isTyping = false
    @Published var suggestedQuestions: [String] = []
    
    private let apiKey = "YOUR_OPENAI_API_KEY_HERE"
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init() {
        loadWelcomeMessage()
        loadSuggestedQuestions()
    }
    
    func loadWelcomeMessage() {
        let welcomeMessage = AIChatMessage(
            content: "Hello! I'm your AI caregiver assistant. I'm here to help you with questions about Alzheimer's care, provide emotional support, and offer practical advice. How can I help you today?",
            isFromUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }
    
    private func loadSuggestedQuestions() {
        suggestedQuestions = [
            "How can I help Dad remember things better?",
            "What should I do when Dad gets confused?",
            "How do I handle wandering behavior?",
            "What are signs of Alzheimer's progression?",
            "How can I take care of myself as a caregiver?",
            "What activities are good for Dad?",
            "How do I communicate better with Dad?",
            "What should I tell the doctor about Dad's condition?"
        ]
    }
    
    func sendMessage(_ content: String) {
        let userMessage = AIChatMessage(
            content: content,
            isFromUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // Show typing indicator
        isTyping = true
        
        // Send to AI
        Task {
            await processMessage(content)
        }
    }
    
    private func processMessage(_ content: String) async {
        do {
            let response = try await callOpenAI(message: content)
            
            await MainActor.run {
                let aiMessage = AIChatMessage(
                    content: response,
                    isFromUser: false,
                    timestamp: Date()
                )
                messages.append(aiMessage)
                isTyping = false
            }
        } catch {
            await MainActor.run {
                let errorMessage = AIChatMessage(
                    content: "I'm sorry, I'm having trouble connecting right now. Please try again later.",
                    isFromUser: false,
                    timestamp: Date()
                )
                messages.append(errorMessage)
                isTyping = false
            }
        }
    }
    
    private func callOpenAI(message: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw AIChatbotError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = """
        You are an AI caregiver assistant specializing in Alzheimer's disease care. You provide:
        1. Practical advice for daily care
        2. Emotional support for caregivers
        3. Medical information (but always recommend consulting healthcare professionals)
        4. Safety tips and strategies
        5. Communication techniques
        6. Activity suggestions
        7. Self-care advice for caregivers
        
        Be empathetic, supportive, and practical. Use simple language and provide actionable advice.
        """
        
        let requestBody = OpenAIRequest(
            model: "gpt-3.5-turbo",
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: message)
            ],
            maxTokens: 500,
            temperature: 0.7
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIChatbotError.invalidResponse
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw AIChatbotError.noContent
        }
        
        return content
    }
    
    func getQuickTips() -> [QuickTip] {
        return [
            QuickTip(
                title: "Memory Aids",
                description: "Use photos, labels, and routines to help with memory",
                category: .memory
            ),
            QuickTip(
                title: "Communication",
                description: "Speak slowly, use simple words, and maintain eye contact",
                category: .communication
            ),
            QuickTip(
                title: "Safety First",
                description: "Remove hazards, install locks, and use GPS tracking",
                category: .safety
            ),
            QuickTip(
                title: "Self-Care",
                description: "Take breaks, ask for help, and join support groups",
                category: .selfCare
            ),
            QuickTip(
                title: "Activities",
                description: "Engage in music, art, and familiar hobbies",
                category: .activities
            ),
            QuickTip(
                title: "Medical Care",
                description: "Keep detailed records and communicate with doctors",
                category: .medical
            )
        ]
    }
    
    func getEmergencyGuidance() -> [EmergencyGuidance] {
        return [
            EmergencyGuidance(
                title: "Wandering",
                description: "Stay calm, search nearby areas, contact authorities if needed",
                steps: [
                    "Check familiar places first",
                    "Contact neighbors and family",
                    "Call 911 if missing for more than 1 hour",
                    "Have recent photo ready"
                ]
            ),
            EmergencyGuidance(
                title: "Aggressive Behavior",
                description: "Ensure safety, remain calm, and redirect attention",
                steps: [
                    "Stay calm and don't argue",
                    "Remove triggers if possible",
                    "Use gentle redirection",
                    "Call for help if needed"
                ]
            ),
            EmergencyGuidance(
                title: "Confusion",
                description: "Provide reassurance and simple explanations",
                steps: [
                    "Stay calm and patient",
                    "Use simple, clear language",
                    "Provide familiar objects",
                    "Contact doctor if severe"
                ]
            )
        ]
    }
}

// MARK: - Data Models

struct AIChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

struct QuickTip: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: TipCategory
}

struct EmergencyGuidance: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let steps: [String]
}

enum TipCategory: String, CaseIterable {
    case memory = "Memory"
    case communication = "Communication"
    case safety = "Safety"
    case selfCare = "Self-Care"
    case activities = "Activities"
    case medical = "Medical"
    
    var color: Color {
        switch self {
        case .memory: return .purple
        case .communication: return .blue
        case .safety: return .red
        case .selfCare: return .green
        case .activities: return .orange
        case .medical: return .cyan
        }
    }
    
    var icon: String {
        switch self {
        case .memory: return "brain.head.profile"
        case .communication: return "message.fill"
        case .safety: return "shield.fill"
        case .selfCare: return "heart.fill"
        case .activities: return "gamecontroller.fill"
        case .medical: return "cross.fill"
        }
    }
}

// MARK: - OpenAI API Models

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

// MARK: - Errors

enum AIChatbotError: Error {
    case invalidURL
    case invalidResponse
    case noContent
    case networkError
}
