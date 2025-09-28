//
//  MockVoiceReminder.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/27/25.
//

import SwiftUI
import AVFoundation

// MARK: - Mock Reminder Model
struct MockReminder: Identifiable {
    let id = UUID()
    let type: MockReminderType
    let title: String
    let personName: String?
    let description: String
    let time: String
    let date: String
    let priority: MockReminderPriority
}

enum MockReminderType: String, CaseIterable {
    case medication = "medication"
    case appointment = "appointment"
    case general = "general"
    
    var icon: String {
        switch self {
        case .medication: return "pills.fill"
        case .appointment: return "stethoscope"
        case .general: return "bell.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .medication: return .red
        case .appointment: return .blue
        case .general: return .green
        }
    }
}

enum MockReminderPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Mock Voice Manager
class MockVoiceManager: ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var showReminderForm = false
    @Published var errorMessage: String?
    
    private let synthesizer = AVSpeechSynthesizer()
    
    func startRecording() {
        isRecording = true
        errorMessage = nil
        
        // Simulate processing after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isRecording = false
            self.isProcessing = true
            
            // Simulate processing for 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.isProcessing = false
                self.showReminderForm = true
            }
        }
    }
    
    func stopRecording() {
        isRecording = false
        isProcessing = false
    }
    
    func speakConfirmation(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.volume = 0.8
        synthesizer.speak(utterance)
    }
}

// MARK: - Mock Voice Reminder View
struct MockVoiceReminderView: View {
    @StateObject private var voiceManager = MockVoiceManager()
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
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .sheet(isPresented: $voiceManager.showReminderForm) {
            ReminderFormView { reminder in
                newReminder = reminder
                voiceManager.showReminderForm = false
                // Speak confirmation
                voiceManager.speakConfirmation("Reminder created: \(reminder.title)")
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

// MARK: - Reminder Form View
struct ReminderFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var type: MockReminderType = .general
    @State private var title = ""
    @State private var personName = ""
    @State private var description = ""
    @State private var time = ""
    @State private var date = ""
    @State private var priority: MockReminderPriority = .medium
    
    let onSave: (MockReminder) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Reminder Details") {
                    Picker("Type", selection: $type) {
                        ForEach(MockReminderType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.rawValue.capitalized)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Title", text: $title)
                    TextField("Person Name (optional)", text: $personName)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Schedule") {
                    TextField("Time (e.g., 8:00 PM)", text: $time)
                    TextField("Date (e.g., Tomorrow)", text: $date)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(MockReminderPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue.capitalized)
                            }
                            .tag(priority)
                        }
                    }
                }
                
                Section {
                    Button("Save Reminder") {
                        let reminder = MockReminder(
                            type: type,
                            title: title.isEmpty ? "New Reminder" : title,
                            personName: personName.isEmpty ? nil : personName,
                            description: description,
                            time: time.isEmpty ? "Not specified" : time,
                            date: date.isEmpty ? "Not specified" : date,
                            priority: priority
                        )
                        onSave(reminder)
                    }
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("Create Reminder")
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

// MARK: - Mock Reminder Card
struct MockReminderCard: View {
    let reminder: MockReminder
    
    var body: some View {
        HStack {
            Image(systemName: reminder.type.icon)
                .font(.title2)
                .foregroundColor(reminder.type.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                    .foregroundColor(.black)
                
                if let personName = reminder.personName {
                    Text("For: \(personName)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text("\(reminder.date) at \(reminder.time)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Circle()
                    .fill(reminder.priority.color)
                    .frame(width: 12, height: 12)
                
                Text(reminder.priority.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(reminder.priority.color)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}
