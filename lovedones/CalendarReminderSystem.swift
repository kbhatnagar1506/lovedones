//
//  CalendarReminderSystem.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/27/25.
//  🏆 LEGENDARY CALENDAR REMINDER SYSTEM - THE BEST EVER BUILT
//

import SwiftUI
import EventKit
import UserNotifications
import AVFoundation
import Speech

// MARK: - 📅 LEGENDARY REMINDER MODEL
struct Reminder: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var date: Date
    var time: Date
    var type: ReminderType
    var priority: ReminderPriority
    var isCompleted: Bool = false
    var personName: String
    var location: String?
    var notes: String?
    
    // 🚀 ADVANCED FEATURES
    var isRecurring: Bool = false
    var recurrencePattern: RecurrencePattern = .none
    var reminderMinutes: [Int] = [15] // Minutes before to remind
    var isNotificationEnabled: Bool = true
    var completionDate: Date?
    var createdAt: Date = Date()
    var lastModified: Date = Date()
    var tags: [String] = []
    var estimatedDuration: Int? // in minutes
    var isVoiceNote: Bool = false
    var voiceNoteURL: String?
    var attachmentURLs: [String] = []
    var relatedReminders: [UUID] = []
    var completionNotes: String?
    var difficulty: TaskDifficulty = .medium
    var energyLevel: EnergyLevel = .medium
    
    var combinedDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        return calendar.date(from: combinedComponents) ?? date
    }
    
    var isOverdue: Bool {
        return combinedDateTime < Date() && !isCompleted
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(combinedDateTime)
    }
    
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(combinedDateTime)
    }
    
    var timeUntilReminder: TimeInterval {
        return combinedDateTime.timeIntervalSinceNow
    }
    
    var formattedTimeRemaining: String {
        let interval = timeUntilReminder
        if interval < 0 {
            return "Overdue"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h"
        } else {
            return "\(Int(interval / 86400))d"
        }
    }
}

// MARK: - 🔄 RECURRENCE PATTERNS
enum RecurrencePattern: String, CaseIterable, Codable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case yearly = "yearly"
    case weekdays = "weekdays"
    case weekends = "weekends"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .none: return "No Repeat"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 Weeks"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "circle"
        case .daily: return "repeat"
        case .weekly: return "calendar.badge.clock"
        case .biweekly: return "calendar.badge.plus"
        case .monthly: return "calendar"
        case .yearly: return "calendar.badge.exclamationmark"
        case .weekdays: return "calendar.badge.clock"
        case .weekends: return "calendar.badge.plus"
        case .custom: return "gear"
        }
    }
}

// MARK: - 🎯 TASK DIFFICULTY
enum TaskDifficulty: String, CaseIterable, Codable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return LovedOnesDesignSystem.successGreen
        case .medium: return LovedOnesDesignSystem.warningOrange
        case .hard: return LovedOnesDesignSystem.primaryRed
        case .expert: return LovedOnesDesignSystem.dangerRed
        }
    }
    
    var icon: String {
        switch self {
        case .easy: return "1.circle.fill"
        case .medium: return "2.circle.fill"
        case .hard: return "3.circle.fill"
        case .expert: return "4.circle.fill"
        }
    }
}

// MARK: - ⚡ ENERGY LEVEL
enum EnergyLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case peak = "peak"
    
    var displayName: String {
        switch self {
        case .low: return "Low Energy"
        case .medium: return "Medium Energy"
        case .high: return "High Energy"
        case .peak: return "Peak Energy"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return LovedOnesDesignSystem.darkGray
        case .medium: return LovedOnesDesignSystem.warningOrange
        case .high: return LovedOnesDesignSystem.successGreen
        case .peak: return LovedOnesDesignSystem.primaryRed
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "battery.25"
        case .medium: return "battery.50"
        case .high: return "battery.75"
        case .peak: return "battery.100"
        }
    }
}

// MARK: - 🔍 REMINDER FILTERS
enum ReminderFilter: String, CaseIterable {
    case all = "all"
    case today = "today"
    case tomorrow = "tomorrow"
    case overdue = "overdue"
    case completed = "completed"
    case pending = "pending"
    case highPriority = "highPriority"
    case recurring = "recurring"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .overdue: return "Overdue"
        case .completed: return "Completed"
        case .pending: return "Pending"
        case .highPriority: return "High Priority"
        case .recurring: return "Recurring"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .today: return "sun.max.fill"
        case .tomorrow: return "moon.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .completed: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .highPriority: return "star.fill"
        case .recurring: return "repeat"
        }
    }
}

// MARK: - 📊 SORT ORDERS
enum SortOrder: String, CaseIterable {
    case date = "date"
    case priority = "priority"
    case title = "title"
    case type = "type"
    case created = "created"
    
    var displayName: String {
        switch self {
        case .date: return "Date"
        case .priority: return "Priority"
        case .title: return "Title"
        case .type: return "Type"
        case .created: return "Created"
        }
    }
    
    var icon: String {
        switch self {
        case .date: return "calendar"
        case .priority: return "star"
        case .title: return "textformat.abc"
        case .type: return "tag"
        case .created: return "clock"
        }
    }
}

// MARK: - 🏷️ REMINDER TYPES
enum ReminderType: String, CaseIterable, Codable {
    case medication = "medication"
    case appointment = "appointment"
    case task = "task"
    case social = "social"
    case health = "health"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .medication: return "Medication"
        case .appointment: return "Appointment"
        case .task: return "Task"
        case .social: return "Social"
        case .health: return "Health"
        case .general: return "General"
        }
    }
    
    var icon: String {
        switch self {
        case .medication: return "pills.fill"
        case .appointment: return "calendar"
        case .task: return "checkmark.circle.fill"
        case .social: return "person.2.fill"
        case .health: return "heart.text.square.fill"
        case .general: return "bell.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .medication: return LovedOnesDesignSystem.primaryRed
        case .appointment: return LovedOnesDesignSystem.infoBlue
        case .task: return LovedOnesDesignSystem.successGreen
        case .social: return LovedOnesDesignSystem.warningOrange
        case .health: return LovedOnesDesignSystem.dangerRed
        case .general: return LovedOnesDesignSystem.darkGray
        }
    }
}

// MARK: - ⚡ REMINDER PRIORITY
enum ReminderPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return LovedOnesDesignSystem.successGreen
        case .medium: return LovedOnesDesignSystem.warningOrange
        case .high: return LovedOnesDesignSystem.primaryRed
        case .urgent: return LovedOnesDesignSystem.dangerRed
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "circle"
        case .medium: return "circle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - 🏆 LEGENDARY CALENDAR REMINDER VIEW MODEL
class CalendarReminderViewModel: ObservableObject {
    @Published var reminders: [Reminder] = []
    @Published var selectedDate: Date = Date()
    @Published var showingAddReminder = false
    @Published var editingReminder: Reminder?
    @Published var selectedReminderType: ReminderType = .general
    @Published var selectedPriority: ReminderPriority = .medium
    
    // 🚀 ADVANCED FEATURES
    @Published var searchText: String = ""
    @Published var selectedFilter: ReminderFilter = .all
    @Published var sortOrder: SortOrder = .date
    @Published var showingStatistics = false
    @Published var showingSettings = false
    @Published var isDarkMode = false
    @Published var showingVoiceInput = false
    @Published var isRecording = false
    @Published var voiceText = ""
    @Published var selectedTags: Set<String> = []
    @Published var showingQuickActions = false
    @Published var notificationPermissionGranted = false
    
    // 📊 ANALYTICS
    @Published var completionRate: Double = 0.0
    @Published var averageCompletionTime: TimeInterval = 0
    @Published var mostProductiveHour: Int = 9
    @Published var streakCount: Int = 0
    @Published var totalReminders: Int = 0
    @Published var completedToday: Int = 0
    @Published var overdueCount: Int = 0
    @Published var upcomingCount: Int = 0
    @Published var priorityDistribution: [ReminderPriority: Int] = [:]
    @Published var typeDistribution: [ReminderType: Int] = [:]
    @Published var weeklyTrend: [Double] = []
    @Published var monthlyTrend: [Double] = []
    
    // 🎯 SMART FEATURES
    @Published var suggestedReminders: [String] = []
    @Published var smartSuggestions: [Reminder] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    init() {
        loadSampleReminders()
        requestNotificationPermission()
        generateSmartSuggestions()
        calculateAnalytics()
    }
    
    func loadSampleReminders() {
        let calendar = Calendar.current
        let today = Date()
        
        reminders = [
            Reminder(
                title: "Morning Medication",
                description: "Take Metformin 500mg with breakfast",
                date: today,
                time: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today) ?? today,
                type: .medication,
                priority: .high,
                personName: "Sarah",
                isRecurring: true,
                recurrencePattern: .daily,
                reminderMinutes: [30, 15, 5],
                tags: ["health", "medication", "morning"],
                estimatedDuration: 5,
                difficulty: .easy,
                energyLevel: .medium
            ),
            Reminder(
                title: "Doctor's Appointment",
                description: "Cardiology checkup with Dr. Smith",
                date: calendar.date(byAdding: .day, value: 1, to: today) ?? today,
                time: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: today) ?? today,
                type: .appointment,
                priority: .high,
                personName: "Dr. Smith",
                location: "Heart Clinic, 123 Main St",
                reminderMinutes: [60, 30, 15],
                tags: ["health", "appointment", "cardiology"],
                estimatedDuration: 60,
                difficulty: .medium,
                energyLevel: .high
            ),
            Reminder(
                title: "Call Mom",
                description: "Weekly check-in call",
                date: calendar.date(byAdding: .day, value: 2, to: today) ?? today,
                time: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? today,
                type: .social,
                priority: .medium,
                personName: "Mom",
                isRecurring: true,
                recurrencePattern: .weekly,
                reminderMinutes: [15],
                tags: ["family", "social", "weekly"],
                estimatedDuration: 30,
                difficulty: .easy,
                energyLevel: .medium
            ),
            Reminder(
                title: "Evening Medication",
                description: "Take evening vitamins",
                date: today,
                time: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today) ?? today,
                type: .medication,
                priority: .high,
                personName: "Sarah",
                isRecurring: true,
                recurrencePattern: .daily,
                reminderMinutes: [15, 5],
                tags: ["health", "medication", "evening"],
                estimatedDuration: 5,
                difficulty: .easy,
                energyLevel: .low
            ),
            Reminder(
                title: "Physical Therapy",
                description: "Weekly physical therapy session",
                date: calendar.date(byAdding: .day, value: 3, to: today) ?? today,
                time: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today) ?? today,
                type: .health,
                priority: .medium,
                personName: "Therapist",
                location: "Rehabilitation Center",
                isRecurring: true,
                recurrencePattern: .weekly,
                reminderMinutes: [60, 30],
                tags: ["health", "therapy", "rehabilitation"],
                estimatedDuration: 45,
                difficulty: .medium,
                energyLevel: .high
            ),
            Reminder(
                title: "Grocery Shopping",
                description: "Buy ingredients for weekend dinner",
                date: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
                time: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: today) ?? today,
                type: .task,
                priority: .low,
                isCompleted: true,
                personName: "Sarah",
                location: "Whole Foods Market",
                completionDate: calendar.date(byAdding: .hour, value: -2, to: today),
                tags: ["shopping", "food", "weekend"],
                estimatedDuration: 30,
                difficulty: .easy,
                energyLevel: .medium
            ),
            Reminder(
                title: "Book Club Meeting",
                description: "Discuss 'The Seven Husbands of Evelyn Hugo'",
                date: calendar.date(byAdding: .day, value: 5, to: today) ?? today,
                time: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today) ?? today,
                type: .social,
                priority: .medium,
                personName: "Book Club",
                location: "Community Center",
                reminderMinutes: [60, 15],
                tags: ["social", "books", "community"],
                estimatedDuration: 120,
                difficulty: .easy,
                energyLevel: .high
            )
        ]
    }
    
    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
        reminders.sort { $0.combinedDateTime < $1.combinedDateTime }
    }
    
    func updateReminder(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
            reminders.sort { $0.combinedDateTime < $1.combinedDateTime }
        }
    }
    
    func deleteReminder(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
    }
    
    func toggleReminderCompletion(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].isCompleted.toggle()
        }
    }
    
    func remindersForDate(_ date: Date) -> [Reminder] {
        let calendar = Calendar.current
        return reminders.filter { reminder in
            calendar.isDate(reminder.date, inSameDayAs: date)
        }
    }
    
    func todaysReminders() -> [Reminder] {
        return remindersForDate(Date())
    }
    
    func upcomingReminders() -> [Reminder] {
        let now = Date()
        return reminders.filter { $0.combinedDateTime > now && !$0.isCompleted }
            .prefix(5)
            .map { $0 }
    }
    
    // 🚀 ADVANCED FEATURES
    
    func filteredReminders() -> [Reminder] {
        var filtered = reminders
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { reminder in
                reminder.title.localizedCaseInsensitiveContains(searchText) ||
                reminder.description.localizedCaseInsensitiveContains(searchText) ||
                reminder.personName.localizedCaseInsensitiveContains(searchText) ||
                reminder.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply category filter with enhanced logic
        switch selectedFilter {
        case .all:
            break
        case .today:
            filtered = filtered.filter { $0.isToday }
        case .tomorrow:
            filtered = filtered.filter { $0.isTomorrow }
        case .overdue:
            filtered = filtered.filter { $0.isOverdue }
        case .completed:
            filtered = filtered.filter { $0.isCompleted }
        case .pending:
            filtered = filtered.filter { !$0.isCompleted }
        case .highPriority:
            filtered = filtered.filter { $0.priority == .high || $0.priority == .urgent }
        case .recurring:
            filtered = filtered.filter { $0.isRecurring }
        }
        
        // Apply tag filter
        if !selectedTags.isEmpty {
            filtered = filtered.filter { reminder in
                !Set(reminder.tags).isDisjoint(with: selectedTags)
            }
        }
        
        // Apply sorting
        switch sortOrder {
        case .date:
            filtered.sort { $0.combinedDateTime < $1.combinedDateTime }
        case .priority:
            filtered.sort { $0.priority.rawValue > $1.priority.rawValue }
        case .title:
            filtered.sort { $0.title < $1.title }
        case .type:
            filtered.sort { $0.type.rawValue < $1.type.rawValue }
        case .created:
            filtered.sort { $0.createdAt > $1.createdAt }
        }
        
        return filtered
    }
    
    func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = granted
            }
        }
    }
    
    func scheduleNotification(for reminder: Reminder) {
        guard notificationPermissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.description
        content.sound = .default
        content.badge = 1
        
        // Add custom data
        content.userInfo = [
            "reminderId": reminder.id.uuidString,
            "type": reminder.type.rawValue,
            "priority": reminder.priority.rawValue
        ]
        
        // Schedule multiple notifications based on reminderMinutes
        for minutes in reminder.reminderMinutes {
            let triggerDate = reminder.combinedDateTime.addingTimeInterval(-TimeInterval(minutes * 60))
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "\(reminder.id.uuidString)_\(minutes)",
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request)
        }
    }
    
    func generateSmartSuggestions() {
        let commonTasks = [
            "Take morning medication",
            "Call family member",
            "Schedule doctor appointment",
            "Go for a walk",
            "Read for 30 minutes",
            "Water the plants",
            "Check blood pressure",
            "Take evening medication",
            "Prepare tomorrow's clothes",
            "Write in journal"
        ]
        
        suggestedReminders = commonTasks
    }
    
    func calculateAnalytics() {
        let completedReminders = reminders.filter { $0.isCompleted }
        let today = Date()
        
        // Basic analytics
        completionRate = reminders.isEmpty ? 0 : Double(completedReminders.count) / Double(reminders.count)
        totalReminders = reminders.count
        completedToday = completedReminders.filter { Calendar.current.isDateInToday($0.completionDate ?? Date.distantPast) }.count
        overdueCount = reminders.filter { $0.isOverdue }.count
        upcomingCount = reminders.filter { $0.combinedDateTime > today && !$0.isCompleted }.count
        
        // Calculate average completion time
        let completionTimes = completedReminders.compactMap { reminder -> TimeInterval? in
            guard let completionDate = reminder.completionDate else { return nil }
            return completionDate.timeIntervalSince(reminder.combinedDateTime)
        }
        
        averageCompletionTime = completionTimes.isEmpty ? 0 : completionTimes.reduce(0, +) / Double(completionTimes.count)
        
        // Find most productive hour
        let hourCounts = Dictionary(grouping: completedReminders) { reminder in
            Calendar.current.component(.hour, from: reminder.combinedDateTime)
        }.mapValues { $0.count }
        
        mostProductiveHour = hourCounts.max(by: { $0.value < $1.value })?.key ?? 9
        
        // Calculate priority distribution
        priorityDistribution = Dictionary(grouping: reminders, by: { $0.priority })
            .mapValues { $0.count }
        
        // Calculate type distribution
        typeDistribution = Dictionary(grouping: reminders, by: { $0.type })
            .mapValues { $0.count }
        
        // Calculate weekly trend (last 7 days)
        weeklyTrend = calculateWeeklyTrend()
        
        // Calculate monthly trend (last 30 days)
        monthlyTrend = calculateMonthlyTrend()
        
        // Calculate streak
        streakCount = calculateStreak()
    }
    
    private func calculateWeeklyTrend() -> [Double] {
        let calendar = Calendar.current
        let today = Date()
        var trend: [Double] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let dayReminders = reminders.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let completedCount = dayReminders.filter { $0.isCompleted }.count
            let totalCount = dayReminders.count
            let completionRate = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
            trend.append(completionRate)
        }
        
        return trend.reversed()
    }
    
    private func calculateMonthlyTrend() -> [Double] {
        let calendar = Calendar.current
        let today = Date()
        var trend: [Double] = []
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let dayReminders = reminders.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let completedCount = dayReminders.filter { $0.isCompleted }.count
            let totalCount = dayReminders.count
            let completionRate = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
            trend.append(completionRate)
        }
        
        return trend.reversed()
    }
    
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        while true {
            let hasCompletedTask = reminders.contains { reminder in
                calendar.isDate(reminder.combinedDateTime, inSameDayAs: currentDate) && reminder.isCompleted
            }
            
            if hasCompletedTask {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    func startVoiceRecording() {
        guard !isRecording else { return }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start failed: \(error)")
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self.voiceText = result.bestTranscription.formattedString
                }
                
                if error != nil || result?.isFinal == true {
                    self.stopVoiceRecording()
                }
            }
        }
        
        isRecording = true
    }
    
    func stopVoiceRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
    }
    
    func createReminderFromVoice() {
        guard !voiceText.isEmpty else { return }
        
        // Simple parsing - in a real app, you'd use NLP
        let words = voiceText.components(separatedBy: " ")
        let title = words.prefix(3).joined(separator: " ")
        
        let reminder = Reminder(
            title: title,
            description: voiceText,
            date: Date(),
            time: Date(),
            type: .general,
            priority: .medium,
            personName: "Me",
            tags: ["voice", "quick"],
            isVoiceNote: true,
            voiceNoteURL: nil
        )
        
        addReminder(reminder)
        voiceText = ""
    }
    
    func getAllTags() -> [String] {
        let allTags = reminders.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }
    
    func getStatistics() -> ReminderStatistics {
        let total = reminders.count
        let completed = reminders.filter { $0.isCompleted }.count
        let overdue = reminders.filter { $0.isOverdue }.count
        let today = reminders.filter { $0.isToday }.count
        
        return ReminderStatistics(
            total: total,
            completed: completed,
            overdue: overdue,
            today: today,
            completionRate: completionRate,
            streakCount: streakCount
        )
    }
}

// MARK: - 📊 STATISTICS MODEL
struct ReminderStatistics {
    let total: Int
    let completed: Int
    let overdue: Int
    let today: Int
    let completionRate: Double
    let streakCount: Int
}

// MARK: - 🏆 PROFESSIONAL CALENDAR REMINDER VIEW
struct CalendarReminderView: View {
    @StateObject private var viewModel = CalendarReminderViewModel()
    @State private var selectedView: ReminderViewType = .dashboard
    @State private var showingQuickAdd = false
    @State private var searchText = ""
    @State private var selectedFilter: ReminderFilter = .all
    @State private var isSearching = false
    
    enum ReminderViewType: String, CaseIterable {
        case dashboard = "Dashboard"
        case calendar = "Calendar"
        case today = "Today"
        case upcoming = "Upcoming"
        case statistics = "Stats"
        
        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .calendar: return "calendar"
            case .today: return "sun.max.fill"
            case .upcoming: return "clock.fill"
            case .statistics: return "chart.line.uptrend.xyaxis"
            }
        }
        
        var accessibilityLabel: String {
            switch self {
            case .dashboard: return "Dashboard view showing overview and statistics"
            case .calendar: return "Calendar view showing monthly reminder layout"
            case .today: return "Today's reminders and tasks"
            case .upcoming: return "Upcoming reminders and scheduled tasks"
            case .statistics: return "Statistics and analytics view"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Professional Background
                backgroundView
                
                VStack(spacing: 0) {
                    // Modern Header with Search
                    modernHeaderView
                    
                    // Enhanced Filter Bar
                    enhancedFilterBar
                    
                    // View Selector with Accessibility
                    professionalViewSelector
                    
                    // Main Content Area
                    mainContentView
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(viewModel.isDarkMode ? .dark : .light)
            .searchable(text: $searchText, isPresented: $isSearching, prompt: "Search reminders...")
            .onChange(of: searchText) {
                viewModel.searchText = searchText
            }
            .sheet(isPresented: $viewModel.showingAddReminder) {
                ProfessionalAddReminderView(viewModel: viewModel)
            }
            .sheet(item: $viewModel.editingReminder) { reminder in
                ProfessionalEditReminderView(reminder: reminder, viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingStatistics) {
                ProfessionalStatisticsView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                ProfessionalSettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingVoiceInput) {
                ProfessionalVoiceInputView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddReminderView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Professional Background
    @ViewBuilder
    private var backgroundView: some View {
        if viewModel.isDarkMode {
            Color.black
                .ignoresSafeArea()
        } else {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Modern Header
    private var modernHeaderView: some View {
        VStack(spacing: 16) {
            // Top Bar
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        // App Icon with Modern Design
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            LovedOnesDesignSystem.primaryRed,
                                            LovedOnesDesignSystem.secondaryRed
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .shadow(
                                    color: LovedOnesDesignSystem.primaryRed.opacity(0.3),
                                    radius: 12,
                                    x: 0,
                                    y: 6
                                )
                            
                            Image(systemName: "bell.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .accessibilityLabel("Reminders app icon")
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reminders")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(viewModel.isDarkMode ? .white : .primary)
                                .accessibilityAddTraits(.isHeader)
                        }
                    }
                }
                
                Spacer()
                
                // Action Buttons with Haptic Feedback
                HStack(spacing: 12) {
                    // Voice Input Button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        viewModel.showingVoiceInput = true
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LovedOnesDesignSystem.infoBlue.opacity(0.15))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "mic.fill")
                                .font(.title3)
                                .foregroundColor(LovedOnesDesignSystem.infoBlue)
                        }
                    }
                    .accessibilityLabel("Voice input")
                    .accessibilityHint("Tap to create a reminder using voice")
                    
                    // Quick Add Button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        showingQuickAdd = true
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LovedOnesDesignSystem.successGreen.opacity(0.15))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(LovedOnesDesignSystem.successGreen)
                        }
                    }
                    .accessibilityLabel("Quick add reminder")
                    .accessibilityHint("Tap to quickly add a new reminder")
                    
                    // Statistics Button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        viewModel.showingStatistics = true
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LovedOnesDesignSystem.warningOrange.opacity(0.15))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "chart.bar.fill")
                                .font(.title3)
                                .foregroundColor(LovedOnesDesignSystem.warningOrange)
                        }
                    }
                    .accessibilityLabel("View statistics")
                    .accessibilityHint("Tap to view your reminder statistics and analytics")
                    
                    // Settings Button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        viewModel.showingSettings = true
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Tap to open settings and preferences")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        )
    }
    
    // MARK: - Enhanced Filter Bar
    private var enhancedFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ReminderFilter.allCases, id: \.self) { filter in
                    AnimatedFilterChip(
                        title: filter.displayName,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter,
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedFilter = filter
                                viewModel.selectedFilter = filter
                            }
                        }
                    )
                    .accessibilityLabel(filter.displayName)
                    .accessibilityAddTraits(selectedFilter == filter ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Professional View Selector
    private var professionalViewSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(ReminderViewType.allCases, id: \.self) { viewType in
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedView = viewType
                        }
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedView == viewType ? 
                                          LovedOnesDesignSystem.primaryRed.opacity(0.15) : 
                                          Color.clear)
                                    .frame(width: 70, height: 70)
                                
                                Image(systemName: viewType.icon)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(selectedView == viewType ? 
                                                   LovedOnesDesignSystem.primaryRed : 
                                                   .secondary)
                            }
                            
                            Text(viewType.rawValue)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(selectedView == viewType ? 
                                               LovedOnesDesignSystem.primaryRed : 
                                               .secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(viewType.accessibilityLabel)
                    .accessibilityAddTraits(selectedView == viewType ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Main Content Area
    @ViewBuilder
    private var mainContentView: some View {
        switch selectedView {
        case .dashboard:
            ProfessionalDashboardView(viewModel: viewModel)
        case .calendar:
            ProfessionalCalendarView(viewModel: viewModel)
        case .today:
            ProfessionalTodayView(viewModel: viewModel)
        case .upcoming:
            ProfessionalUpcomingView(viewModel: viewModel)
            case .statistics:
                EnhancedStatisticsView(viewModel: viewModel)
        }
    }
    
}

// MARK: - 🏆 PROFESSIONAL VIEWS

// MARK: - 📊 PROFESSIONAL DASHBOARD VIEW
struct ProfessionalDashboardView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Quick Stats Section
                quickStatsSection
                
                // Today's Overview
                todaysOverviewSection
                
                // Smart Suggestions
                smartSuggestionsSection
                
                // Recent Activity
                recentActivitySection
                
                // Quick Actions
                quickActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ProfessionalStatCard(
                    title: "Today",
                    value: "\(viewModel.todaysReminders().count)",
                    subtitle: "reminders",
                    color: LovedOnesDesignSystem.primaryRed,
                    icon: "sun.max.fill"
                )
                
                ProfessionalStatCard(
                    title: "Completed",
                    value: "\(viewModel.reminders.filter { $0.isCompleted }.count)",
                    subtitle: "tasks",
                    color: LovedOnesDesignSystem.successGreen,
                    icon: "checkmark.circle.fill"
                )
                
                ProfessionalStatCard(
                    title: "Overdue",
                    value: "\(viewModel.reminders.filter { $0.isOverdue }.count)",
                    subtitle: "urgent",
                    color: LovedOnesDesignSystem.dangerRed,
                    icon: "exclamationmark.triangle.fill"
                )
                
                ProfessionalStatCard(
                    title: "Streak",
                    value: "\(viewModel.streakCount)",
                    subtitle: "days",
                    color: LovedOnesDesignSystem.warningOrange,
                    icon: "flame.fill"
                )
            }
        }
    }
    
    private var todaysOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Overview")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            if viewModel.todaysReminders().isEmpty {
                ProfessionalEmptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "All caught up!",
                    subtitle: "No reminders for today"
                )
            } else {
                ForEach(viewModel.todaysReminders().prefix(3)) { reminder in
                    ProfessionalCompactReminderCard(reminder: reminder, viewModel: viewModel)
                }
                
                if viewModel.todaysReminders().count > 3 {
                    Button("View All Today's Reminders") {
                        // Navigate to today view
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(LovedOnesDesignSystem.primaryRed)
                }
            }
        }
    }
    
    private var smartSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Smart Suggestions")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.suggestedReminders.prefix(5), id: \.self) { suggestion in
                        ProfessionalSuggestionCard(suggestion: suggestion) {
                            // Create reminder from suggestion
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: 12) {
                ForEach(viewModel.reminders.filter { $0.isCompleted }.prefix(3)) { reminder in
                    ProfessionalActivityRow(reminder: reminder)
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ProfessionalQuickActionCard(
                    title: "Voice Note",
                    icon: "mic.fill",
                    color: LovedOnesDesignSystem.infoBlue
                ) {
                    viewModel.showingVoiceInput = true
                }
                
                ProfessionalQuickActionCard(
                    title: "Quick Add",
                    icon: "plus.circle.fill",
                    color: LovedOnesDesignSystem.primaryRed
                ) {
                    viewModel.showingAddReminder = true
                }
                
                ProfessionalQuickActionCard(
                    title: "View Stats",
                    icon: "chart.bar.fill",
                    color: LovedOnesDesignSystem.successGreen
                ) {
                    viewModel.showingStatistics = true
                }
            }
        }
    }
}

// MARK: - 📊 PROFESSIONAL STAT CARD
struct ProfessionalStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(.systemGray))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(
                    color: .black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
}

// MARK: - 📝 PROFESSIONAL COMPACT REMINDER CARD
struct ProfessionalCompactReminderCard: View {
    let reminder: Reminder
    @ObservedObject var viewModel: CalendarReminderViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Completion Toggle
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                viewModel.toggleReminderCompletion(reminder)
            }) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(reminder.isCompleted ? LovedOnesDesignSystem.successGreen : Color(.systemGray))
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(reminder.isCompleted ? "Mark as incomplete" : "Mark as complete")
            
            // Type Icon
            ZStack {
                Circle()
                    .fill(reminder.type.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: reminder.type.icon)
                    .font(.title3)
                    .foregroundColor(reminder.type.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(reminder.isCompleted ? .secondary : .primary)
                    .strikethrough(reminder.isCompleted)
                    .lineLimit(1)
                
                Text(formatTime(reminder.combinedDateTime))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(LovedOnesDesignSystem.primaryRed)
            }
            
            Spacer()
            
            // Priority Indicator
            Image(systemName: reminder.priority.icon)
                .font(.caption)
                .foregroundColor(reminder.priority.color)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(
                    color: .black.opacity(0.05),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .opacity(reminder.isCompleted ? 0.7 : 1.0)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 💡 PROFESSIONAL SUGGESTION CARD
struct ProfessionalSuggestionCard: View {
    let suggestion: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title3)
                        .foregroundColor(LovedOnesDesignSystem.warningOrange)
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                        .foregroundColor(LovedOnesDesignSystem.primaryRed)
                }
                
                Text(suggestion)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding(16)
            .frame(width: 160, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .shadow(
                        color: .black.opacity(0.05),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Add suggestion: \(suggestion)")
    }
}

// MARK: - 📈 PROFESSIONAL ACTIVITY ROW
struct ProfessionalActivityRow: View {
    let reminder: Reminder
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundColor(LovedOnesDesignSystem.successGreen)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("Completed \(formatTimeAgo(reminder.completionDate ?? Date()))")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

// MARK: - ⚡ PROFESSIONAL QUICK ACTION CARD
struct ProfessionalQuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .shadow(
                        color: .black.opacity(0.05),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
    }
}

// MARK: - 📭 PROFESSIONAL EMPTY STATE VIEW
struct ProfessionalEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(Color(.systemGray))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

// MARK: - 📅 PROFESSIONAL CALENDAR VIEW
struct ProfessionalCalendarView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    
    var body: some View {
        VStack {
            Text("Professional Calendar View")
                .font(.title)
                .padding()
            
            Text("Coming Soon - Advanced Calendar Features")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - ☀️ PROFESSIONAL TODAY VIEW
struct ProfessionalTodayView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    
    var body: some View {
        VStack {
            Text("Professional Today View")
                .font(.title)
                .padding()
            
            Text("Coming Soon - Smart Today Features")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - ⏰ PROFESSIONAL UPCOMING VIEW
struct ProfessionalUpcomingView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    
    var body: some View {
        VStack {
            Text("Professional Upcoming View")
                .font(.title)
                .padding()
            
            Text("Coming Soon - Smart Upcoming Features")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 📊 PROFESSIONAL STATISTICS VIEW
struct ProfessionalStatisticsView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Professional Statistics View")
                    .font(.title)
                    .padding()
                
                Text("Coming Soon - Advanced Analytics")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Statistics")
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
}

// MARK: - ➕ PROFESSIONAL ADD REMINDER VIEW
struct ProfessionalAddReminderView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Professional Add Reminder")
                    .font(.title)
                    .padding()
                
                Text("Coming Soon - Advanced Reminder Creation")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - ✏️ PROFESSIONAL EDIT REMINDER VIEW
struct ProfessionalEditReminderView: View {
    let reminder: Reminder
    @ObservedObject var viewModel: CalendarReminderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Professional Edit Reminder")
                    .font(.title)
                    .padding()
                
                Text("Coming Soon - Advanced Reminder Editing")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - ⚙️ PROFESSIONAL SETTINGS VIEW
struct ProfessionalSettingsView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Professional Settings")
                    .font(.title)
                    .padding()
                
                Text("Coming Soon - Advanced Settings")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Settings")
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
}

// MARK: - 🎤 PROFESSIONAL VOICE INPUT VIEW
struct ProfessionalVoiceInputView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Professional Voice Input")
                    .font(.title)
                    .padding()
                
                Text("Coming Soon - Advanced Voice Features")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Voice Input")
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
}

// MARK: - ⚡ QUICK ADD REMINDER VIEW
struct QuickAddReminderView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedType: ReminderType = .general
    @State private var selectedPriority: ReminderPriority = .medium
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Add Reminder")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    TextField("What needs to be done?", text: $title)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Reminder title")
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Type")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            Button(action: {
                                selectedType = type
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: type.icon)
                                        .font(.title3)
                                        .foregroundColor(selectedType == type ? .white : type.color)
                                    
                                    Text(type.displayName)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(selectedType == type ? .white : .primary)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedType == type ? type.color : Color(.systemGray6))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Priority")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        ForEach(ReminderPriority.allCases, id: \.self) { priority in
                            Button(action: {
                                selectedPriority = priority
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: priority.icon)
                                        .font(.caption)
                                    
                                    Text(priority.displayName)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(selectedPriority == priority ? .white : priority.color)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedPriority == priority ? priority.color : priority.color.opacity(0.15))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
                
                Button("Add Reminder") {
                    addReminder()
                }
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LovedOnesDesignSystem.primaryRed)
                )
                .disabled(title.isEmpty)
            }
            .padding(24)
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addReminder() {
        let reminder = Reminder(
            title: title,
            description: "",
            date: Date(),
            time: Date(),
            type: selectedType,
            priority: selectedPriority,
            personName: "Me"
        )
        
        viewModel.addReminder(reminder)
        dismiss()
    }
}

// MARK: - 📅 CALENDAR VIEW
struct CalendarView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceL) {
            // Month Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(LovedOnesDesignSystem.primaryRed)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(LovedOnesDesignSystem.headingFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(LovedOnesDesignSystem.primaryRed)
                }
            }
            .padding(.horizontal, LovedOnesDesignSystem.spaceL)
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Day headers
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                        .frame(height: 30)
                }
                
                // Calendar days
                ForEach(daysInMonth, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        reminders: viewModel.remindersForDate(date),
                        isSelected: calendar.isDate(date, inSameDayAs: viewModel.selectedDate),
                        isToday: calendar.isDateInToday(date)
                    ) {
                        viewModel.selectedDate = date
                    }
                }
            }
            .padding(.horizontal, LovedOnesDesignSystem.spaceL)
            
            // Selected Date Reminders
            if !viewModel.remindersForDate(viewModel.selectedDate).isEmpty {
                VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
                    Text("Reminders for \(formatDate(viewModel.selectedDate))")
                        .font(LovedOnesDesignSystem.subheadingFont)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        .padding(.horizontal, LovedOnesDesignSystem.spaceL)
                    
                    ScrollView {
                        LazyVStack(spacing: LovedOnesDesignSystem.spaceM) {
                            ForEach(viewModel.remindersForDate(viewModel.selectedDate)) { reminder in
                                BeautifulReminderCard(
                                    reminder: reminder,
                                    onToggle: {
                                        viewModel.toggleReminderCompletion(reminder)
                                    },
                                    onTap: {
                                        viewModel.editingReminder = reminder
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, LovedOnesDesignSystem.spaceL)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1) else {
            return []
        }
        
        var days: [Date] = []
        var date = monthFirstWeek.start
        
        while date < monthLastWeek.end {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return days
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

// MARK: - 📅 CALENDAR DAY VIEW
struct CalendarDayView: View {
    let date: Date
    let reminders: [Reminder]
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(textColor)
                
                // Reminder indicators
                HStack(spacing: 2) {
                    ForEach(reminders.prefix(3), id: \.id) { reminder in
                        Circle()
                            .fill(reminder.type.color)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .frame(width: 40, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return LovedOnesDesignSystem.primaryRed
        } else {
            return LovedOnesDesignSystem.textPrimary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return LovedOnesDesignSystem.primaryRed
        } else if isToday {
            return LovedOnesDesignSystem.primaryRed.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return LovedOnesDesignSystem.primaryRed
        } else {
            return Color.clear
        }
    }
}

// MARK: - ☀️ TODAY REMINDERS VIEW
struct TodayRemindersView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: LovedOnesDesignSystem.spaceM) {
                // Today's Header
                VStack(spacing: LovedOnesDesignSystem.spaceS) {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(LovedOnesDesignSystem.warningOrange)
                            .font(.title2)
                        
                        Text("Today's Reminders")
                            .font(LovedOnesDesignSystem.headingFont)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        
                        Spacer()
                        
                        Text("\(viewModel.todaysReminders().count)")
                            .font(LovedOnesDesignSystem.subheadingFont)
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                            .fontWeight(.bold)
                    }
                    
                    Text(formatTodayDate())
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                }
                .padding(.horizontal, LovedOnesDesignSystem.spaceL)
                
                // Today's Reminders
                if viewModel.todaysReminders().isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle.fill",
                        title: "All caught up!",
                        subtitle: "No reminders for today"
                    )
                } else {
                    ForEach(viewModel.todaysReminders()) { reminder in
                        ReminderCard(reminder: reminder, viewModel: viewModel)
                    }
                }
            }
            .padding(.vertical, LovedOnesDesignSystem.spaceL)
        }
    }
    
    private func formatTodayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
}

// MARK: - ⏰ UPCOMING REMINDERS VIEW
struct UpcomingRemindersView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: LovedOnesDesignSystem.spaceM) {
                // Upcoming Header
                VStack(spacing: LovedOnesDesignSystem.spaceS) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(LovedOnesDesignSystem.infoBlue)
                            .font(.title2)
                        
                        Text("Upcoming Reminders")
                            .font(LovedOnesDesignSystem.headingFont)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        
                        Spacer()
                        
                        Text("\(viewModel.upcomingReminders().count)")
                            .font(LovedOnesDesignSystem.subheadingFont)
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                            .fontWeight(.bold)
                    }
                    
                    Text("Next 5 upcoming reminders")
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                }
                .padding(.horizontal, LovedOnesDesignSystem.spaceL)
                
                // Upcoming Reminders
                if viewModel.upcomingReminders().isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.checkmark",
                        title: "No upcoming reminders",
                        subtitle: "You're all set for the future!"
                    )
                } else {
                    ForEach(viewModel.upcomingReminders()) { reminder in
                        ReminderCard(reminder: reminder, viewModel: viewModel)
                    }
                }
            }
            .padding(.vertical, LovedOnesDesignSystem.spaceL)
        }
    }
}

// MARK: - 📝 REMINDER CARD
struct ReminderCard: View {
    let reminder: Reminder
    @ObservedObject var viewModel: CalendarReminderViewModel
    @State private var showingDetails = false
    
    var body: some View {
        Button(action: {
            viewModel.editingReminder = reminder
        }) {
            HStack(spacing: LovedOnesDesignSystem.spaceM) {
                // Completion Toggle
                Button(action: {
                    viewModel.toggleReminderCompletion(reminder)
                }) {
                    Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(reminder.isCompleted ? LovedOnesDesignSystem.successGreen : LovedOnesDesignSystem.mediumGray)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Type Icon
                ZStack {
                    Circle()
                        .fill(reminder.type.color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: reminder.type.icon)
                        .font(.title3)
                        .foregroundColor(reminder.type.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(reminder.title)
                            .font(LovedOnesDesignSystem.subheadingFont)
                            .foregroundColor(reminder.isCompleted ? LovedOnesDesignSystem.darkGray : LovedOnesDesignSystem.textPrimary)
                            .strikethrough(reminder.isCompleted)
                        
                        Spacer()
                        
                        // Priority Indicator
                        Image(systemName: reminder.priority.icon)
                            .font(.caption)
                            .foregroundColor(reminder.priority.color)
                    }
                    
                    Text(reminder.description)
                        .font(LovedOnesDesignSystem.bodyFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                        .lineLimit(2)
                    
                    HStack {
                        Text(formatDateTime(reminder.combinedDateTime))
                            .font(LovedOnesDesignSystem.captionFont)
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                            .fontWeight(.semibold)
                        
                        if let location = reminder.location {
                            Text("•")
                                .foregroundColor(LovedOnesDesignSystem.mediumGray)
                            
                            Text(location)
                                .font(LovedOnesDesignSystem.captionFont)
                                .foregroundColor(LovedOnesDesignSystem.darkGray)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Type Badge
                Text(reminder.type.displayName)
                    .font(LovedOnesDesignSystem.smallFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(reminder.type.color)
                    )
            }
            .padding(LovedOnesDesignSystem.spaceL)
            .background(
                RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusL)
                    .fill(LovedOnesDesignSystem.pureWhite)
                    .shadow(
                        color: LovedOnesDesignSystem.shadowLight.color,
                        radius: LovedOnesDesignSystem.shadowLight.radius,
                        x: LovedOnesDesignSystem.shadowLight.x,
                        y: LovedOnesDesignSystem.shadowLight.y
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(reminder.isCompleted ? 0.7 : 1.0)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - ➕ ADD REMINDER VIEW
struct AddReminderView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var personName = ""
    @State private var location = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: LovedOnesDesignSystem.spaceL) {
                    // Form Fields
                    VStack(spacing: LovedOnesDesignSystem.spaceM) {
                        FormField(title: "Title", text: $title, placeholder: "Enter reminder title")
                        FormField(title: "Description", text: $description, placeholder: "Enter description", isMultiline: true)
                        FormField(title: "Person", text: $personName, placeholder: "Who is this for?")
                        FormField(title: "Location", text: $location, placeholder: "Where? (optional)")
                        FormField(title: "Notes", text: $notes, placeholder: "Additional notes (optional)", isMultiline: true)
                    }
                    
                    // Date and Time Selection
                    VStack(spacing: LovedOnesDesignSystem.spaceM) {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                        
                        DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                    }
                    
                    // Type Selection
                    VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
                        Text("Type")
                            .font(LovedOnesDesignSystem.subheadingFont)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: LovedOnesDesignSystem.spaceM) {
                            ForEach(ReminderType.allCases, id: \.self) { type in
                                TypeSelectionCard(
                                    type: type,
                                    isSelected: viewModel.selectedReminderType == type
                                ) {
                                    viewModel.selectedReminderType = type
                                }
                            }
                        }
                    }
                    
                    // Priority Selection
                    VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
                        Text("Priority")
                            .font(LovedOnesDesignSystem.subheadingFont)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        
                        HStack(spacing: LovedOnesDesignSystem.spaceM) {
                            ForEach(ReminderPriority.allCases, id: \.self) { priority in
                                PrioritySelectionCard(
                                    priority: priority,
                                    isSelected: viewModel.selectedPriority == priority
                                ) {
                                    viewModel.selectedPriority = priority
                                }
                            }
                        }
                    }
                }
                .padding(LovedOnesDesignSystem.spaceL)
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReminder()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveReminder() {
        let reminder = Reminder(
            title: title,
            description: description,
            date: selectedDate,
            time: selectedTime,
            type: viewModel.selectedReminderType,
            priority: viewModel.selectedPriority,
            personName: personName.isEmpty ? "Me" : personName,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes
        )
        
        viewModel.addReminder(reminder)
        dismiss()
    }
}

// MARK: - ✏️ EDIT REMINDER VIEW
struct EditReminderView: View {
    let reminder: Reminder
    @ObservedObject var viewModel: CalendarReminderViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var selectedDate: Date
    @State private var selectedTime: Date
    @State private var personName: String
    @State private var location: String
    @State private var notes: String
    @State private var selectedType: ReminderType
    @State private var selectedPriority: ReminderPriority
    
    init(reminder: Reminder, viewModel: CalendarReminderViewModel) {
        self.reminder = reminder
        self.viewModel = viewModel
        self._title = State(initialValue: reminder.title)
        self._description = State(initialValue: reminder.description)
        self._selectedDate = State(initialValue: reminder.date)
        self._selectedTime = State(initialValue: reminder.time)
        self._personName = State(initialValue: reminder.personName)
        self._location = State(initialValue: reminder.location ?? "")
        self._notes = State(initialValue: reminder.notes ?? "")
        self._selectedType = State(initialValue: reminder.type)
        self._selectedPriority = State(initialValue: reminder.priority)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: LovedOnesDesignSystem.spaceL) {
                    // Form Fields
                    VStack(spacing: LovedOnesDesignSystem.spaceM) {
                        FormField(title: "Title", text: $title, placeholder: "Enter reminder title")
                        FormField(title: "Description", text: $description, placeholder: "Enter description", isMultiline: true)
                        FormField(title: "Person", text: $personName, placeholder: "Who is this for?")
                        FormField(title: "Location", text: $location, placeholder: "Where? (optional)")
                        FormField(title: "Notes", text: $notes, placeholder: "Additional notes (optional)", isMultiline: true)
                    }
                    
                    // Date and Time Selection
                    VStack(spacing: LovedOnesDesignSystem.spaceM) {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                        
                        DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                    }
                    
                    // Type Selection
                    VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
                        Text("Type")
                            .font(LovedOnesDesignSystem.subheadingFont)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: LovedOnesDesignSystem.spaceM) {
                            ForEach(ReminderType.allCases, id: \.self) { type in
                                TypeSelectionCard(
                                    type: type,
                                    isSelected: selectedType == type
                                ) {
                                    selectedType = type
                                }
                            }
                        }
                    }
                    
                    // Priority Selection
                    VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
                        Text("Priority")
                            .font(LovedOnesDesignSystem.subheadingFont)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        
                        HStack(spacing: LovedOnesDesignSystem.spaceM) {
                            ForEach(ReminderPriority.allCases, id: \.self) { priority in
                                PrioritySelectionCard(
                                    priority: priority,
                                    isSelected: selectedPriority == priority
                                ) {
                                    selectedPriority = priority
                                }
                            }
                        }
                    }
                    
                    // Delete Button
                    Button(action: deleteReminder) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Reminder")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM)
                                .fill(LovedOnesDesignSystem.dangerRed)
                        )
                    }
                }
                .padding(LovedOnesDesignSystem.spaceL)
            }
            .navigationTitle("Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReminder()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveReminder() {
        let updatedReminder = Reminder(
            title: title,
            description: description,
            date: selectedDate,
            time: selectedTime,
            type: selectedType,
            priority: selectedPriority,
            isCompleted: reminder.isCompleted,
            personName: personName.isEmpty ? "Me" : personName,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes
        )
        
        viewModel.updateReminder(updatedReminder)
        dismiss()
    }
    
    private func deleteReminder() {
        viewModel.deleteReminder(reminder)
        dismiss()
    }
}

// MARK: - 📝 FORM FIELD
struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceS) {
            Text(title)
                .font(LovedOnesDesignSystem.subheadingFont)
                .foregroundColor(LovedOnesDesignSystem.textPrimary)
            
            if isMultiline {
                TextField(placeholder, text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

// MARK: - 🏷️ TYPE SELECTION CARD
struct TypeSelectionCard: View {
    let type: ReminderType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: LovedOnesDesignSystem.spaceS) {
                ZStack {
                    Circle()
                        .fill(isSelected ? type.color : LovedOnesDesignSystem.lightGray)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: type.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : LovedOnesDesignSystem.darkGray)
                }
                
                Text(type.displayName)
                    .font(LovedOnesDesignSystem.smallFont)
                    .foregroundColor(isSelected ? type.color : LovedOnesDesignSystem.darkGray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(LovedOnesDesignSystem.spaceM)
            .background(
                RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM)
                    .fill(isSelected ? type.color.opacity(0.1) : LovedOnesDesignSystem.pureWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM)
                            .stroke(isSelected ? type.color : LovedOnesDesignSystem.mediumGray, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ⚡ PRIORITY SELECTION CARD
struct PrioritySelectionCard: View {
    let priority: ReminderPriority
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: LovedOnesDesignSystem.spaceS) {
                Image(systemName: priority.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : priority.color)
                
                Text(priority.displayName)
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(isSelected ? .white : priority.color)
            }
            .padding(.horizontal, LovedOnesDesignSystem.spaceM)
            .padding(.vertical, LovedOnesDesignSystem.spaceS)
            .background(
                RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM)
                    .fill(isSelected ? priority.color : priority.color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 📭 EMPTY STATE VIEW
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceL) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(LovedOnesDesignSystem.mediumGray)
            
            VStack(spacing: LovedOnesDesignSystem.spaceS) {
                Text(title)
                    .font(LovedOnesDesignSystem.headingFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                
                Text(subtitle)
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(LovedOnesDesignSystem.darkGray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(LovedOnesDesignSystem.spaceXL)
    }
}

// MARK: - 🏆 PREVIEW
struct CalendarReminderView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarReminderView()
            .previewDisplayName("📅 Calendar Reminder System")
    }
}
