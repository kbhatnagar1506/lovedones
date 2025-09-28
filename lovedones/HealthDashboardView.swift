//
//  HealthDashboardView.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/28/25.
//

import SwiftUI
import HealthKit

struct HealthDashboardView: View {
    @StateObject private var healthManager = HealthKitManager()
    @StateObject private var taskManager = TaskManager()
    @EnvironmentObject var authManager: UserAuthManager
    @State private var showingHealthKitAuth = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Selector
                tabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    // Health Overview
                    healthOverviewView
                        .tag(0)
                    
                    // Task Manager
                    taskManagerView
                        .tag(1)
                    
                    // Medications
                    medicationsView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Health & Tasks")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if !healthManager.isAuthorized {
                    showingHealthKitAuth = true
                } else {
                    healthManager.loadHealthData()
                }
            }
            .sheet(isPresented: $showingHealthKitAuth) {
                HealthKitPermissionView(healthManager: healthManager)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Good \(timeOfDayGreeting), \(authManager.currentUser?.name ?? "User")")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("How are you feeling today?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Sync status with caregiver
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Data shared with Alex")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    healthManager.loadHealthData()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                        Text("Update")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            
            // Quick Stats
            if healthManager.isAuthorized {
                quickStatsView
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Night"
        }
    }
    
    private var quickStatsView: some View {
        VStack(spacing: 12) {
            // Primary health metrics
            HStack(spacing: 16) {
                QuickStatCard(
                    title: "Mood Today",
                    value: "\(moodScore)/10",
                    subtitle: moodTrend,
                    progress: Double(moodScore) / 10.0,
                    color: moodColor
                )
                
                QuickStatCard(
                    title: "Memory",
                    value: "\(memoryScore)%",
                    subtitle: memoryTrend,
                    progress: Double(memoryScore) / 100.0,
                    color: memoryColor
                )
                
                QuickStatCard(
                    title: "Sleep",
                    value: healthManager.healthData.sleepHours != nil ? String(format: "%.1f hrs", healthManager.healthData.sleepHours!) : "No data",
                    subtitle: healthManager.healthData.sleepStatus,
                    progress: nil,
                    color: .blue
                )
            }
            
            // Secondary metrics
            HStack(spacing: 16) {
                QuickStatCard(
                    title: "Steps",
                    value: "\(healthManager.healthData.steps)",
                    subtitle: "Goal: 10,000",
                    progress: healthManager.healthData.stepsProgress,
                    color: .green
                )
                
                QuickStatCard(
                    title: "Heart Rate",
                    value: healthManager.healthData.heartRate != nil ? "\(Int(healthManager.healthData.heartRate!)) BPM" : "No data",
                    subtitle: healthManager.healthData.heartRateStatus,
                    progress: nil,
                    color: .red
                )
                
                QuickStatCard(
                    title: "Medication",
                    value: "\(medicationCompliance)%",
                    subtitle: "Compliance",
                    progress: Double(medicationCompliance) / 100.0,
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Health Metrics (matching caregiver dashboard)
    private var moodScore: Int { 7 } // This would come from actual mood tracking
    private var memoryScore: Int { 75 } // This would come from cognitive assessments
    private var medicationCompliance: Int { 95 } // This would come from medication tracking
    
    private var moodTrend: String {
        // This would be calculated from recent mood data
        return "↗️ Good"
    }
    
    private var memoryTrend: String {
        // This would be calculated from recent memory tests
        return "→ Stable"
    }
    
    private var moodColor: Color {
        switch moodScore {
        case 8...10: return .green
        case 6...7: return .orange
        default: return .red
        }
    }
    
    private var memoryColor: Color {
        switch memoryScore {
        case 80...100: return .green
        case 60...79: return .orange
        default: return .red
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "Health", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabButton(title: "Tasks", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            TabButton(title: "Medications", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Health Overview
    private var healthOverviewView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Health Metrics Cards
                if healthManager.isAuthorized {
                    HealthMetricCard(
                        title: "Daily Steps",
                        value: "\(healthManager.healthData.steps)",
                        goal: "10,000",
                        progress: healthManager.healthData.stepsProgress,
                        icon: "figure.walk",
                        color: .green
                    )
                    
                    if let heartRate = healthManager.healthData.heartRate {
                        HealthMetricCard(
                            title: "Heart Rate",
                            value: "\(Int(heartRate)) BPM",
                            goal: "60-100 BPM",
                            progress: nil,
                            icon: "heart.fill",
                            color: .red
                        )
                    }
                    
                    if let sleepHours = healthManager.healthData.sleepHours {
                        HealthMetricCard(
                            title: "Sleep",
                            value: String(format: "%.1f hours", sleepHours),
                            goal: "7-9 hours",
                            progress: nil,
                            icon: "bed.double.fill",
                            color: .blue
                        )
                    }
                    
                    if let bp = healthManager.healthData.bloodPressure {
                        BloodPressureCard(reading: bp)
                    }
                } else {
                    HealthKitPermissionPrompt()
                }
                
                // Today's Tasks Summary
                if !taskManager.todayTasks.isEmpty {
                    TodayTasksSummary(tasks: taskManager.todayTasks)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Task Manager
    private var taskManagerView: some View {
        TaskManagerView(taskManager: taskManager)
    }
    
    // MARK: - Medications
    private var medicationsView: some View {
        MedicationsView(healthManager: healthManager)
    }
}

// MARK: - Supporting Views
struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double?
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if let progress = progress {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .blue : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                )
        }
    }
}

struct HealthMetricCard: View {
    let title: String
    let value: String
    let goal: String
    let progress: Double?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Goal: \(goal)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let progress = progress {
                    VStack {
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        ProgressView(value: progress)
                            .progressViewStyle(CircularProgressViewStyle(tint: color))
                            .frame(width: 40, height: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct BloodPressureCard: View {
    let reading: BloodPressureReading
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("Blood Pressure")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(bloodPressureStatus)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(bloodPressureColor.opacity(0.2))
                    .foregroundColor(bloodPressureColor)
                    .cornerRadius(4)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(reading.systolic)/\(reading.diastolic)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("mmHg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Last reading")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(reading.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var bloodPressureStatus: String {
        if reading.systolic < 90 || reading.diastolic < 60 { return "Low" }
        else if reading.systolic > 140 || reading.diastolic > 90 { return "High" }
        else { return "Normal" }
    }
    
    private var bloodPressureColor: Color {
        if reading.systolic < 90 || reading.diastolic < 60 { return .blue }
        else if reading.systolic > 140 || reading.diastolic > 90 { return .red }
        else { return .green }
    }
}

struct TodayTasksSummary: View {
    let tasks: [HealthTaskItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Today's Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(completedCount)/\(tasks.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(tasks.prefix(3)) { task in
                HStack {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .gray)
                    
                    Text(task.title)
                        .font(.subheadline)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                    
                    Spacer()
                    
                    Text(task.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(task.category.color.opacity(0.2))
                        .foregroundColor(task.category.color)
                        .cornerRadius(4)
                }
            }
            
            if tasks.count > 3 {
                Text("+ \(tasks.count - 3) more tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var completedCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
}

struct HealthKitPermissionPrompt: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Connect Health App")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Allow LovedOnes to read your health data to provide personalized insights and reminders.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Enable Health Integration") {
                // This will be handled by the parent view
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    HealthDashboardView()
}
