//
//  TaskManagerView.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/28/25.
//

import SwiftUI

struct TaskManagerView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var showingAddTask = false
    @State private var selectedFilter: TaskFilter = .all
    @State private var searchText = ""
    
    enum TaskFilter: String, CaseIterable {
        case all = "all"
        case pending = "pending"
        case completed = "completed"
        case today = "today"
        case overdue = "overdue"
        
        var displayName: String {
            switch self {
            case .all: return "All"
            case .pending: return "Pending"
            case .completed: return "Completed"
            case .today: return "Today"
            case .overdue: return "Overdue"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Stats
            headerView
            
            // Filter Tabs
            filterTabs
            
            // Search Bar
            searchBar
            
            // Tasks List
            tasksList
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddTask = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(taskManager: taskManager)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Task Overview")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Stay organized and healthy")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(taskManager.completionRate * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick Stats
            HStack(spacing: 16) {
                TaskStatCard(
                    title: "Today",
                    value: "\(taskManager.tasksDueToday)",
                    color: .blue
                )
                
                TaskStatCard(
                    title: "Completed",
                    value: "\(taskManager.tasksCompletedToday)",
                    color: .green
                )
                
                TaskStatCard(
                    title: "Overdue",
                    value: "\(taskManager.overdueTasks.count)",
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Filter Tabs
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter,
                        count: tasksForFilter(filter).count
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search tasks...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Tasks List
    private var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredTasks) { task in
                    TaskCard(
                        task: task,
                        onToggleCompletion: {
                            taskManager.toggleTaskCompletion(task)
                        },
                        onEdit: {
                            // Handle edit
                        },
                        onDelete: {
                            taskManager.deleteTask(task)
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    private var filteredTasks: [HealthTaskItem] {
        var tasks = tasksForFilter(selectedFilter)
        
        if !searchText.isEmpty {
            tasks = tasks.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return tasks.sorted { first, second in
            // Sort by priority first, then by due date
            if first.priority != second.priority {
                return priorityOrder(first.priority) < priorityOrder(second.priority)
            }
            
            if let firstDate = first.dueDate, let secondDate = second.dueDate {
                return firstDate < secondDate
            }
            
            return first.createdAt > second.createdAt
        }
    }
    
    private func tasksForFilter(_ filter: TaskFilter) -> [HealthTaskItem] {
        switch filter {
        case .all:
            return taskManager.tasks
        case .pending:
            return taskManager.pendingTasks
        case .completed:
            return taskManager.completedTasks
        case .today:
            return taskManager.todayTasks
        case .overdue:
            return taskManager.overdueTasks
        }
    }
    
    private func priorityOrder(_ priority: TaskPriority) -> Int {
        switch priority {
        case .urgent: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

// MARK: - Supporting Views
struct TaskStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct TaskCard: View {
    let task: HealthTaskItem
    let onToggleCompletion: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion Button
            Button(action: onToggleCompletion) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            // Task Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                    
                    Spacer()
                    
                    // Priority Badge
                    Text(task.priority.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(task.priority.color.opacity(0.2))
                        .foregroundColor(task.priority.color)
                        .cornerRadius(4)
                }
                
                Text(task.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    // Category
                    HStack(spacing: 4) {
                        Image(systemName: task.category.icon)
                            .font(.caption)
                        Text(task.category.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(task.category.color)
                    
                    Spacer()
                    
                    // Due Date
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Menu Button
            Menu {
                Button("Edit", action: onEdit)
                Button("Delete", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @ObservedObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory = TaskCategory.medication
    @State private var selectedPriority = TaskPriority.medium
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var isRecurring = false
    @State private var selectedRecurrence = RecurrencePattern.daily
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Category & Priority") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                Text(category.displayName)
                            }
                            .tag(category)
                        }
                    }
                    
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                }
                
                Section("Schedule") {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                    
                    Toggle("Recurring", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Repeat", selection: $selectedRecurrence) {
                            ForEach(RecurrencePattern.allCases, id: \.self) { pattern in
                                Text(pattern.displayName).tag(pattern)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        let newTask = HealthTaskItem(
            title: title,
            description: description,
            category: selectedCategory,
            priority: selectedPriority,
            dueDate: hasDueDate ? dueDate : nil,
            isRecurring: isRecurring,
            recurrencePattern: isRecurring ? selectedRecurrence : nil
        )
        
        taskManager.addTask(newTask)
        dismiss()
    }
}

#Preview {
    TaskManagerView(taskManager: TaskManager())
}
