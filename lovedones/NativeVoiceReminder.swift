//
//  NativeVoiceReminder.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/27/25.
//

import SwiftUI
import Speech
import AVFoundation
import Foundation

// MARK: - Reminder Response Model
struct ReminderResponse: Codable {
    let type: String
    let title: String
    let personName: String?
    let payload: [String: String]
    let naturalLanguage: String
    let timezone: String
    let priority: String
}

// MARK: - Native Voice Manager
class NativeVoiceManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var transcribedText = ""
    @Published var reminderData: ReminderResponse?
    @Published var showPreview = false
    @Published var errorMessage: String?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private let openAIAPIKey = "YOUR_OPENAI_API_KEY_HERE"
    
    override init() {
        super.init()
        requestPermissions()
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    self.errorMessage = "Speech recognition not authorized"
                @unknown default:
                    self.errorMessage = "Speech recognition error"
                }
            }
        }
    }
    
    func startRecording() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition not available"
            return
        }
        
        isRecording = true
        transcribedText = ""
        errorMessage = nil
        
        // Cancel previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session setup failed: \(error.localizedDescription)"
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Audio engine failed to start: \(error.localizedDescription)"
            return
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    self?.errorMessage = "Recognition error: \(error.localizedDescription)"
                    self?.stopRecording()
                }
            }
        }
    }
    
    func stopRecording() {
        isRecording = false
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Process the transcribed text
        if !transcribedText.isEmpty {
            processTranscribedText(transcribedText)
        }
    }
    
    private func processTranscribedText(_ text: String) {
        isProcessing = true
        
        Task {
            do {
                let reminder = try await callOpenAI(text: text)
                await MainActor.run {
                    self.reminderData = reminder
                    self.showPreview = true
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to process reminder: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func callOpenAI(text: String) async throws -> ReminderResponse {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = """
        You are a voice reminder assistant for an Alzheimer's support app called Cherish. 
        Parse the user's spoken reminder and return ONLY a JSON object with this exact structure:
        
        {
          "type": "med|appointment|general",
          "title": "Brief title",
          "personName": "Name or null",
          "payload": {
            "drugName": "Medication name (if med)",
            "strength": "Dosage (if med)",
            "instructions": "Special instructions",
            "time": "Time in 24h format (e.g., 20:00)",
            "days": "Days of week (if recurring)",
            "datetime": "ISO date for appointments",
            "clinic": "Clinic name (if appointment)",
            "address": "Address (if appointment)",
            "description": "Description (if general)",
            "dueDate": "ISO date (if general)"
          },
          "naturalLanguage": "What the user said",
          "timezone": "America/New_York",
          "priority": "time_sensitive|standard"
        }
        
        Rules:
        - Convert times to 24h format
        - Convert relative dates to absolute dates
        - Use "time_sensitive" for meds/appointments, "standard" for general
        - Extract person names when mentioned
        - Return ONLY the JSON, no other text
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.1,
            "max_tokens": 1000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "OpenAIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let choices = jsonResponse["choices"] as! [[String: Any]]
        let message = choices[0]["message"] as! [String: Any]
        let content = message["content"] as! String
        
        // Parse the JSON response
        let jsonData = content.data(using: .utf8)!
        let reminder = try JSONDecoder().decode(ReminderResponse.self, from: jsonData)
        
        return reminder
    }
}

// MARK: - Native Voice Reminder View
struct NativeVoiceReminderView: View {
    @StateObject private var voiceManager = NativeVoiceManager()
    @State private var newReminder: MockReminder?
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            Text("Voice Reminder")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text("Tap and speak your reminder")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Voice Button with States
            Button(action: {
                if voiceManager.isRecording {
                    voiceManager.stopRecording()
                } else {
                    voiceManager.startRecording()
                }
            }) {
                ZStack {
                    // Background pulse animation
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .scaleEffect(voiceManager.isRecording ? 1.2 : 1.0)
                        .opacity(voiceManager.isRecording ? 0.6 : 0.3)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: voiceManager.isRecording)
                    
                    // Main button
                    Circle()
                        .fill(buttonColor)
                        .frame(width: 120, height: 120)
                        .scaleEffect(voiceManager.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: voiceManager.isRecording)
                    
                    // Button content
                    if voiceManager.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    } else {
                        Image(systemName: buttonIcon)
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                }
            }
            .accessibilityLabel(buttonAccessibilityLabel)
            .disabled(voiceManager.isProcessing)
            
            // Status text
            Text(statusText)
                .font(.caption)
                .foregroundColor(statusColor)
                .animation(.easeInOut, value: voiceManager.isRecording)
                .animation(.easeInOut, value: voiceManager.isProcessing)
            
            // Transcribed text
            if !voiceManager.transcribedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("You said:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(voiceManager.transcribedText)
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .sheet(isPresented: $voiceManager.showPreview) {
            if let reminderData = voiceManager.reminderData {
                NativePreviewCard(reminderData: reminderData) { savedReminder in
                    newReminder = savedReminder
                    voiceManager.showPreview = false
                }
            }
        }
        .alert("Error", isPresented: .constant(voiceManager.errorMessage != nil)) {
            Button("OK") {
                voiceManager.errorMessage = nil
            }
        } message: {
            if let error = voiceManager.errorMessage {
                Text(error)
            }
        }
    }
    
    private var buttonColor: Color {
        if voiceManager.isProcessing {
            return .orange
        } else if voiceManager.isRecording {
            return .red
        } else {
            return .blue
        }
    }
    
    private var buttonIcon: String {
        if voiceManager.isRecording {
            return "stop.fill"
        } else {
            return "mic.fill"
        }
    }
    
    private var statusText: String {
        if voiceManager.isProcessing {
            return "Processing your reminder..."
        } else if voiceManager.isRecording {
            return "Listening... Speak now"
        } else {
            return "Tap to start recording"
        }
    }
    
    private var statusColor: Color {
        if voiceManager.isProcessing {
            return .orange
        } else if voiceManager.isRecording {
            return .red
        } else {
            return .gray
        }
    }
    
    private var buttonAccessibilityLabel: String {
        if voiceManager.isProcessing {
            return "Processing"
        } else if voiceManager.isRecording {
            return "Stop recording"
        } else {
            return "Start recording"
        }
    }
}

// MARK: - Native Preview Card
struct NativePreviewCard: View {
    let reminderData: ReminderResponse
    let onSave: (MockReminder) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(iconColor.opacity(0.12)))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reminderData.title)
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text(reminderData.type.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(priorityColor.opacity(0.2)))
                            .foregroundColor(priorityColor)
                    }
                    
                    Spacer()
                }
                
                // Natural language
                Text(reminderData.naturalLanguage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                
                // Details
                VStack(alignment: .leading, spacing: 8) {
                    if let personName = reminderData.personName {
                        DetailRow(label: "For", value: personName)
                    }
                    
                    if let time = reminderData.payload["time"] {
                        DetailRow(label: "Time", value: time)
                    }
                    
                    if let drugName = reminderData.payload["drugName"] {
                        DetailRow(label: "Medication", value: drugName)
                    }
                    
                    if let strength = reminderData.payload["strength"] {
                        DetailRow(label: "Strength", value: strength)
                    }
                    
                    if let instructions = reminderData.payload["instructions"] {
                        DetailRow(label: "Instructions", value: instructions)
                    }
                    
                    if let clinic = reminderData.payload["clinic"] {
                        DetailRow(label: "Clinic", value: clinic)
                    }
                    
                    if let description = reminderData.payload["description"] {
                        DetailRow(label: "Description", value: description)
                    }
                }
                
                Spacer()
                
                // Save Button
                Button(action: {
                    let mockReminder = convertToMockReminder(reminderData)
                    onSave(mockReminder)
                }) {
                    Text("Save Reminder")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Preview Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var iconName: String {
        switch reminderData.type {
        case "med": return "pills.fill"
        case "appointment": return "stethoscope"
        default: return "bell.fill"
        }
    }
    
    private var iconColor: Color {
        switch reminderData.type {
        case "med": return .red
        case "appointment": return .blue
        default: return .green
        }
    }
    
    private var priorityColor: Color {
        switch reminderData.priority {
        case "time_sensitive": return .red
        default: return .blue
        }
    }
    
    private func convertToMockReminder(_ data: ReminderResponse) -> MockReminder {
        let type: MockReminderType
        switch data.type {
        case "med": type = .medication
        case "appointment": type = .appointment
        default: type = .general
        }
        
        let priority: MockReminderPriority
        switch data.priority {
        case "time_sensitive": priority = .high
        default: priority = .medium
        }
        
        let time = data.payload["time"] ?? "Not specified"
        let date = data.payload["datetime"] ?? data.payload["dueDate"] ?? "Not specified"
        let description = data.payload["description"] ?? data.payload["instructions"] ?? ""
        
        return MockReminder(
            type: type,
            title: data.title,
            personName: data.personName,
            description: description,
            time: time,
            date: date,
            priority: priority
        )
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.black)
            
            Spacer()
        }
    }
}




