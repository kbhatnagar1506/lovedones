//
//  ServerBasedVoiceReminder.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/27/25.
//

import SwiftUI
import Speech
import AVFoundation
import Foundation

// MARK: - Server Configuration
struct ServerConfig {
    static let voiceReminderServer = "https://lovedones-voice-reminders-0470ae371d84.herokuapp.com"
    static let emergencyCallingServer = "https://lovedones-emergency-calling-6db36c5e88ab.herokuapp.com"
}

// MARK: - Reminder Response Model
struct ServerReminderResponse: Codable {
    let success: Bool
    let reminder: ReminderData?
    let message: String?
}

struct ReminderData: Codable {
    let type: String
    let title: String
    let personName: String?
    let payload: [String: AnyCodable]
    let naturalLanguage: String
    let timezone: String
    let priority: String
}

// Helper for handling Any type in JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - Server Voice Manager
class ServerVoiceManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var transcribedText = ""
    @Published var reminderData: ReminderData?
    @Published var showPreview = false
    @Published var errorMessage: String?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
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
        
        // Cancel any previous task
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
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
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Audio engine start failed: \(error.localizedDescription)"
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
        
        isRecording = true
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
                let reminder = try await callVoiceReminderServer(text: text)
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
    
    private func callVoiceReminderServer(text: String) async throws -> ReminderData {
        guard let url = URL(string: "\(ServerConfig.voiceReminderServer)/process-voice-reminder") else {
            throw NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }
        
        let serverResponse = try JSONDecoder().decode(ServerReminderResponse.self, from: data)
        
        guard serverResponse.success, let reminder = serverResponse.reminder else {
            throw NSError(domain: "ProcessingError", code: 0, userInfo: [NSLocalizedDescriptionKey: serverResponse.message ?? "Failed to process reminder"])
        }
        
        return reminder
    }
    
    func createEmergencyCall() {
        Task {
            do {
                let result = try await callEmergencyServer()
                await MainActor.run {
                    if result.success {
                        print("Emergency call initiated: \(result.message ?? "")")
                    } else {
                        self.errorMessage = result.message ?? "Failed to initiate emergency call"
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Emergency call failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func callEmergencyServer() async throws -> ServerReminderResponse {
        guard let url = URL(string: "\(ServerConfig.emergencyCallingServer)/emergency-call") else {
            throw NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(ServerReminderResponse.self, from: data)
    }
}

// MARK: - Server Voice Reminder View
struct ServerBasedVoiceReminderView: View {
    @StateObject private var voiceManager = ServerVoiceManager()
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
                    Text("Transcribed:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(voiceManager.transcribedText)
                        .font(.body)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Emergency Call Button
            Button(action: {
                voiceManager.createEmergencyCall()
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Emergency Call")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .sheet(isPresented: $voiceManager.showPreview) {
            if let reminderData = voiceManager.reminderData {
                ServerReminderPreviewView(reminderData: reminderData) { reminder in
                    newReminder = reminder
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
            return "Processing your request..."
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

// MARK: - Server Reminder Preview View
struct ServerReminderPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let reminderData: ReminderData
    let onSave: (MockReminder) -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Reminder Preview")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type: \(reminderData.type.capitalized)")
                        .font(.headline)
                    
                    Text("Title: \(reminderData.title)")
                        .font(.subheadline)
                    
                    if let personName = reminderData.personName {
                        Text("Person: \(personName)")
                            .font(.subheadline)
                    }
                    
                    Text("Priority: \(reminderData.priority.capitalized)")
                        .font(.subheadline)
                    
                    Text("Description: \(reminderData.naturalLanguage)")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
                
                Button("Save Reminder") {
                    let reminder = MockReminder(
                        type: MockReminderType(rawValue: reminderData.type) ?? .general,
                        title: reminderData.title,
                        personName: reminderData.personName,
                        description: reminderData.naturalLanguage,
                        time: "Not specified",
                        date: "Not specified",
                        priority: MockReminderPriority(rawValue: reminderData.priority) ?? .medium
                    )
                    onSave(reminder)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Preview")
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
}

// Mock reminder types are defined in MockVoiceReminder.swift
