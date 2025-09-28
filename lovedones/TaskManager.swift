//
//  TaskManager.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/28/25.
//

import Foundation
import SwiftUI

// MARK: - Task Models
struct HealthTaskItem: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var category: TaskCategory
    var priority: TaskPriority
    var dueDate: Date?
    var isCompleted: Bool
    var completedDate: Date?
    var reminderTime: Date?
    var isRecurring: Bool
    var recurrencePattern: RecurrencePattern?
    var createdAt: Date
    var updatedAt: Date
    
    init(title: String, description: String, category: TaskCategory, priority: TaskPriority, dueDate: Date? = nil, reminderTime: Date? = nil, isRecurring: Bool = false, recurrencePattern: RecurrencePattern? = nil) {
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.dueDate = dueDate
        self.isCompleted = false
        self.completedDate = nil
        self.reminderTime = reminderTime
        self.isRecurring = isRecurring
        self.recurrencePattern = recurrencePattern
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum TaskCategory: String, CaseIterable, Codable {
    case medication = "medication"
    case exercise = "exercise"
    case appointment = "appointment"
    case healthCheck = "health_check"
    case nutrition = "nutrition"
    case sleep = "sleep"
    case general = "general"
    
    var icon: String {
        switch self {
        case .medication: return "pills.fill"
        case .exercise: return "figure.walk"
        case .appointment: return "calendar"
        case .healthCheck: return "stethoscope"
        case .nutrition: return "fork.knife"
        case .sleep: return "bed.double.fill"
        case .general: return "checkmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .medication: return .red
        case .exercise: return .green
        case .appointment: return .blue
        case .healthCheck: return .orange
        case .nutrition: return .purple
        case .sleep: return .indigo
        case .general: return .gray
        }
    }
    
    var displayName: String {
        switch self {
        case .medication: return "Medication"
        case .exercise: return "Exercise"
        case .appointment: return "Appointment"
        case .healthCheck: return "Health Check"
        case .nutrition: return "Nutrition"
        case .sleep: return "Sleep"
        case .general: return "General"
        }
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
}

// RecurrencePattern is defined in CalendarReminderSystem.swift

// MARK: - Task Manager
class TaskManager: ObservableObject {
    @Published var tasks: [HealthTaskItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadSampleTasks()
    }
    
    func addTask(_ task: HealthTaskItem) {
        tasks.append(task)
        saveTasks()
    }
    
    func updateTask(_ task: HealthTaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            updatedTask.updatedAt = Date()
            tasks[index] = updatedTask
            saveTasks()
        }
    }
    
    func deleteTask(_ task: HealthTaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: HealthTaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            tasks[index].completedDate = tasks[index].isCompleted ? Date() : nil
            tasks[index].updatedAt = Date()
            
            // If it's a recurring task and completed, create next occurrence
            if tasks[index].isCompleted && tasks[index].isRecurring {
                createNextRecurrence(for: tasks[index])
            }
            
            saveTasks()
        }
    }
    
    private func createNextRecurrence(for task: HealthTaskItem) {
        guard let pattern = task.recurrencePattern else { return }
        
        let calendar = Calendar.current
        var nextDueDate: Date?
        
        switch pattern {
        case .daily:
            nextDueDate = calendar.date(byAdding: .day, value: 1, to: task.dueDate ?? Date())
        case .weekly:
            nextDueDate = calendar.date(byAdding: .weekOfYear, value: 1, to: task.dueDate ?? Date())
        case .biweekly:
            nextDueDate = calendar.date(byAdding: .weekOfYear, value: 2, to: task.dueDate ?? Date())
        case .monthly:
            nextDueDate = calendar.date(byAdding: .month, value: 1, to: task.dueDate ?? Date())
        case .yearly:
            nextDueDate = calendar.date(byAdding: .year, value: 1, to: task.dueDate ?? Date())
        case .weekdays:
            // For weekdays, add 1 day and check if it's a weekday
            var nextDay = calendar.date(byAdding: .day, value: 1, to: task.dueDate ?? Date()) ?? Date()
            while calendar.isDateInWeekend(nextDay) {
                nextDay = calendar.date(byAdding: .day, value: 1, to: nextDay) ?? nextDay
            }
            nextDueDate = nextDay
        case .weekends:
            // For weekends, add 1 day and check if it's a weekend
            var nextDay = calendar.date(byAdding: .day, value: 1, to: task.dueDate ?? Date()) ?? Date()
            while !calendar.isDateInWeekend(nextDay) {
                nextDay = calendar.date(byAdding: .day, value: 1, to: nextDay) ?? nextDay
            }
            nextDueDate = nextDay
        case .custom:
            return // Handle custom patterns separately
        case .none:
            return // No recurrence pattern
        }
        
        if let nextDate = nextDueDate {
            let nextTask = HealthTaskItem(
                title: task.title,
                description: task.description,
                category: task.category,
                priority: task.priority,
                dueDate: nextDate,
                reminderTime: task.reminderTime,
                isRecurring: task.isRecurring,
                recurrencePattern: task.recurrencePattern
            )
            addTask(nextTask)
        }
    }
    
    // MARK: - Filtering and Sorting
    var completedTasks: [HealthTaskItem] {
        tasks.filter { $0.isCompleted }
    }
    
    var pendingTasks: [HealthTaskItem] {
        tasks.filter { !$0.isCompleted }
    }
    
    var todayTasks: [HealthTaskItem] {
        let calendar = Calendar.current
        let today = Date()
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: today)
        }
    }
    
    var overdueTasks: [HealthTaskItem] {
        let now = Date()
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < now
        }
    }
    
    var upcomingTasks: [HealthTaskItem] {
        let calendar = Calendar.current
        let now = Date()
        let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now)!
        
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate > now && dueDate <= nextWeek
        }
    }
    
    func tasksForCategory(_ category: TaskCategory) -> [HealthTaskItem] {
        tasks.filter { $0.category == category }
    }
    
    func tasksForPriority(_ priority: TaskPriority) -> [HealthTaskItem] {
        tasks.filter { $0.priority == priority }
    }
    
    // MARK: - Statistics
    var completionRate: Double {
        guard !tasks.isEmpty else { return 0.0 }
        return Double(completedTasks.count) / Double(tasks.count)
    }
    
    var tasksCompletedToday: Int {
        let calendar = Calendar.current
        let today = Date()
        return completedTasks.filter { task in
            guard let completedDate = task.completedDate else { return false }
            return calendar.isDate(completedDate, inSameDayAs: today)
        }.count
    }
    
    var tasksDueToday: Int {
        todayTasks.count
    }
    
    // MARK: - Persistence
    private func saveTasks() {
        // In a real app, this would save to Core Data or UserDefaults
        // For now, we'll just keep them in memory
    }
    
    private func loadSampleTasks() {
        let sampleTasks = [
            HealthTaskItem(
                title: "Take Morning Medication",
                description: "Take blood pressure medication with breakfast",
                category: TaskCategory.medication,
                priority: TaskPriority.high,
                dueDate: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()),
                reminderTime: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()),
                isRecurring: true,
                recurrencePattern: RecurrencePattern.daily
            ),
            HealthTaskItem(
                title: "Morning Walk",
                description: "30-minute walk around the neighborhood",
                category: TaskCategory.exercise,
                priority: TaskPriority.medium,
                dueDate: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
                reminderTime: Calendar.current.date(bySettingHour: 8, minute: 45, second: 0, of: Date()),
                isRecurring: true,
                recurrencePattern: RecurrencePattern.daily
            ),
            HealthTaskItem(
                title: "Doctor Appointment",
                description: "Annual checkup with Dr. Smith",
                category: TaskCategory.appointment,
                priority: TaskPriority.high,
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                reminderTime: Calendar.current.date(byAdding: .day, value: 3, to: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!)
            ),
            HealthTaskItem(
                title: "Blood Pressure Check",
                description: "Check blood pressure and record readings",
                category: TaskCategory.healthCheck,
                priority: TaskPriority.medium,
                dueDate: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()),
                reminderTime: Calendar.current.date(bySettingHour: 17, minute: 45, second: 0, of: Date()),
                isRecurring: true,
                recurrencePattern: RecurrencePattern.daily
            ),
            HealthTaskItem(
                title: "Evening Medication",
                description: "Take evening medication with dinner",
                category: TaskCategory.medication,
                priority: TaskPriority.high,
                dueDate: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()),
                reminderTime: Calendar.current.date(bySettingHour: 18, minute: 45, second: 0, of: Date()),
                isRecurring: true,
                recurrencePattern: RecurrencePattern.daily
            )
        ]
        
        tasks = sampleTasks
    }
}
