//
//  ChatbotService.swift
//  lovedones
//
//  Created by Krishna Bhatnagar on 9/28/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Chatbot Models
struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}

struct ChatbotResponse: Codable {
    let success: Bool
    let response: String?
    let conversationId: String?
    let timestamp: String?
    let error: String?
    let message: String?
}

struct ChatbotSuggestions: Codable {
    let success: Bool
    let suggestions: [String]
    let context: String
}

// MARK: - Chatbot Service
class ChatbotService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var suggestions: [String] = []
    
    private let baseURL = "https://lovedones-chatbot-ai-a03a29532686.herokuapp.com"
    private let session = URLSession.shared
    private var conversationId = UUID().uuidString
    
    init() {
        // Add welcome message
        addMessage(content: "Hello! I'm here to help you with caregiving questions and support. How can I assist you today?", isUser: false)
        loadSuggestions(context: "general")
    }
    
    // MARK: - Public Methods
    
    func sendMessage(_ message: String) {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        addMessage(content: message, isUser: true)
        isLoading = true
        errorMessage = nil
        
        // Send to chatbot server
        Task {
            await sendToChatbot(message: message)
        }
    }
    
    func loadSuggestions(context: String = "general") {
        Task {
            await fetchSuggestions(context: context)
        }
    }
    
    func clearConversation() {
        messages.removeAll()
        conversationId = UUID().uuidString
        addMessage(content: "Hello! I'm here to help you with caregiving questions and support. How can I assist you today?", isUser: false)
        loadSuggestions(context: "general")
    }
    
    // MARK: - Private Methods
    
    private func addMessage(content: String, isUser: Bool) {
        DispatchQueue.main.async {
            let message = ChatMessage(content: content, isUser: isUser)
            self.messages.append(message)
        }
    }
    
    private func sendToChatbot(message: String) async {
        guard let url = URL(string: "\(baseURL)/chat") else {
            await handleError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "message": message
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 Chatbot API Response Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let reply = jsonResponse["response"] as? String {
                        await MainActor.run {
                            self.addMessage(content: reply, isUser: false)
                            self.isLoading = false
                        }
                    } else {
                        await handleError("Invalid response format")
                    }
                } else {
                    let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                    await handleError("Server error: \(httpResponse.statusCode) - \(errorText)")
                }
            }
        } catch {
            print("🔍 Chatbot API Error: \(error)")
            await handleError("Failed to connect to chatbot: \(error.localizedDescription)")
        }
    }
    
    private func fetchSuggestions(context: String) async {
        guard let url = URL(string: "\(baseURL)/suggestions") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["context": context]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let suggestionsResponse = try JSONDecoder().decode(ChatbotSuggestions.self, from: data)
                
                await MainActor.run {
                    self.suggestions = suggestionsResponse.suggestions
                }
            }
        } catch {
            print("🔍 Suggestions API Error: \(error)")
        }
    }
    
    private func handleError(_ message: String) async {
        await MainActor.run {
            self.errorMessage = message
            self.isLoading = false
            self.addMessage(content: "I'm sorry, I'm having trouble connecting right now. Please try again in a moment.", isUser: false)
        }
    }
}

// MARK: - Chatbot View
struct ChatbotView: View {
    @StateObject private var chatbotService = ChatbotService()
    @State private var messageText = ""
    @State private var showingSuggestions = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatbotService.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if chatbotService.isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Thinking...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatbotService.messages.count) { _ in
                        if let lastMessage = chatbotService.messages.last {
                            withAnimation(.easeOut(duration: 0.5)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Suggestions
                if showingSuggestions && !chatbotService.suggestions.isEmpty {
                    SuggestionsView(
                        suggestions: chatbotService.suggestions,
                        onSuggestionTap: { suggestion in
                            messageText = suggestion
                            showingSuggestions = false
                        }
                    )
                }
                
                // Input area
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        TextField("Ask me anything about caregiving...", text: $messageText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                sendMessage()
                            }
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatbotService.isLoading)
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Clear Conversation") {
                            chatbotService.clearConversation()
                        }
                        
                        Button("Memory Care Tips") {
                            chatbotService.loadSuggestions(context: "memory_care")
                        }
                        
                        Button("Daily Care Help") {
                            chatbotService.loadSuggestions(context: "daily_care")
                        }
                        
                        Button("Emotional Support") {
                            chatbotService.loadSuggestions(context: "emotional_support")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(chatbotService.errorMessage != nil)) {
            Button("OK") {
                chatbotService.errorMessage = nil
            }
        } message: {
            Text(chatbotService.errorMessage ?? "")
        }
    }
    
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        chatbotService.sendMessage(message)
        messageText = ""
        showingSuggestions = false
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                
                Spacer()
            }
        }
    }
}

// MARK: - Suggestions View
struct SuggestionsView: View {
    let suggestions: [String]
    let onSuggestionTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested questions:")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: {
                            onSuggestionTap(suggestion)
                        }) {
                            Text(suggestion)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

// MARK: - Preview
struct ChatbotView_Previews: PreviewProvider {
    static var previews: some View {
        ChatbotView()
    }
}
