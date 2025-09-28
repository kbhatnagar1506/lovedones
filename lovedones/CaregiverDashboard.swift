//
//  CaregiverDashboard.swift
//  LovedOnes
//
//  Comprehensive caregiver dashboard for Alzheimer's care
//

import SwiftUI
import MapKit
import Charts

struct CaregiverDashboard: View {
    @StateObject private var healthTracker = HealthTracker()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var aiChatbot = AIChatbot()
    @StateObject private var doctorReportGenerator = DoctorReportGenerator()
    @StateObject private var memoryLane = MemoryLaneManager()
    @EnvironmentObject var authManager: UserAuthManager
    
    @State private var selectedTab = 0
    @State private var showingEmergencyAlert = false
    @State private var showingDoctorReport = false
    @State private var showingLocationMap = false
    @State private var showingAIChat = false
    @State private var lastSyncTime = Date()
    @State private var isSyncing = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Main Dashboard
                mainDashboardView
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Dashboard")
                    }
                    .tag(0)
                
                // Health & Stats
                healthStatsView
                    .tabItem {
                        Image(systemName: "heart.fill")
                        Text("Health")
                    }
                    .tag(1)
                
                // Memory Lane
                memoryLaneView
                    .tabItem {
                        Image(systemName: "photo.fill")
                        Text("Memories")
                    }
                    .tag(2)
                
                // AI Support
                aiSupportView
                    .tabItem {
                        Image(systemName: "brain.head.profile")
                        Text("AI Support")
                    }
                    .tag(3)
                
                // Doctor Reports
                doctorReportsView
                    .tabItem {
                        Image(systemName: "doc.text.fill")
                        Text("Reports")
                    }
                    .tag(4)
            }
            .accentColor(.blue)
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Main Dashboard View
    private var mainDashboardView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with Emergency Button
                headerSection
                
                // Quick Stats Cards
                quickStatsSection
                
                // Today's Activities
                todaysActivitiesSection
                
                // Recent Alerts
                recentAlertsSection
                
                // Quick Actions
                quickActionsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(timeOfDayGreeting), \(authManager.currentUser?.name ?? "Alex")")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Monitoring Dad's Well-being")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Sync status
                    HStack(spacing: 4) {
                        Image(systemName: isSyncing ? "arrow.clockwise" : "checkmark.circle.fill")
                            .foregroundColor(isSyncing ? .orange : .green)
                            .font(.caption)
                        Text(isSyncing ? "Syncing data..." : "Last sync: \(lastSyncTime, formatter: timeFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Emergency Button
                Button(action: {
                    showingEmergencyAlert = true
                    // Trigger VAPI emergency call
                    triggerEmergencyCall()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("EMERGENCY")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80, height: 80)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.red, Color.orange]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
            
            // Current Status
            HStack(spacing: 16) {
                StatusCard(
                    title: "Current Location",
                    value: locationManager.currentLocation ?? "Unknown",
                    icon: "location.fill",
                    color: .blue
                )
                
                StatusCard(
                    title: "Last Seen",
                    value: "2 hours ago",
                    icon: "clock.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Dad's Health Today")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: syncData) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                        Text("Sync")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    title: "Mood Score",
                    value: "\(healthTracker.todayMoodScore)/10",
                    subtitle: healthTracker.moodTrend,
                    color: healthTracker.moodColor,
                    icon: "face.smiling"
                )
                
                StatCard(
                    title: "Memory Test",
                    value: "\(healthTracker.memoryScore)%",
                    subtitle: healthTracker.memoryTrend,
                    color: healthTracker.memoryColor,
                    icon: "brain.head.profile"
                )
                
                StatCard(
                    title: "Sleep Quality",
                    value: "\(healthTracker.sleepScore)/10",
                    subtitle: "7.5 hours",
                    color: healthTracker.sleepColor,
                    icon: "moon.fill"
                )
                
                StatCard(
                    title: "Medication",
                    value: "\(healthTracker.medicationCompliance)%",
                    subtitle: "On time",
                    color: healthTracker.medicationColor,
                    icon: "pills.fill"
                )
            }
        }
    }
    
    // MARK: - Today's Activities Section
    private var todaysActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Activities")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to full activities view
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                ForEach(healthTracker.todaysActivities, id: \.id) { activity in
                    CaregiverActivityRow(activity: activity)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Recent Alerts Section
    private var recentAlertsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Alerts")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(healthTracker.recentAlerts, id: \.id) { alert in
                    AlertRow(alert: alert)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                QuickActionButton(
                    title: "Find Location",
                    icon: "location.fill",
                    color: .blue,
                    action: { showingLocationMap = true }
                )
                
                QuickActionButton(
                    title: "AI Chat",
                    icon: "brain.head.profile",
                    color: .purple,
                    action: { showingAIChat = true }
                )
                
                QuickActionButton(
                    title: "Doctor Report",
                    icon: "doc.text.fill",
                    color: .green,
                    action: { showingDoctorReport = true }
                )
                
                QuickActionButton(
                    title: "Add Memory",
                    icon: "plus.circle.fill",
                    color: .orange,
                    action: { /* Add memory */ }
                )
            }
        }
    }
    
    // MARK: - Health Stats View
    private var healthStatsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Health Overview
                healthOverviewSection
                
                // Cognitive Assessment
                cognitiveAssessmentSection
                
                // Medication Tracking
                medicationTrackingSection
                
                // Sleep Analysis
                sleepAnalysisSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Health Overview Section
    private var healthOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                HealthMetricCard(
                    title: "Overall Health",
                    value: "Good",
                    goal: "Maintain",
                    progress: 0.8,
                    icon: "heart.fill",
                    color: .green
                )
                
                HealthMetricCard(
                    title: "Medication Adherence",
                    value: "\(healthTracker.medicationCompliance)%",
                    goal: "100%",
                    progress: Double(healthTracker.medicationCompliance) / 100.0,
                    icon: "pills.fill",
                    color: .blue
                )
                
                HealthMetricCard(
                    title: "Cognitive Function",
                    value: "\(healthTracker.memoryScore)%",
                    goal: "80%+",
                    progress: Double(healthTracker.memoryScore) / 100.0,
                    icon: "brain.head.profile",
                    color: healthTracker.memoryColor
                )
                
                HealthMetricCard(
                    title: "Mood Stability",
                    value: "\(healthTracker.todayMoodScore)/10",
                    goal: "8+",
                    progress: Double(healthTracker.todayMoodScore) / 10.0,
                    icon: "face.smiling",
                    color: healthTracker.moodColor
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Cognitive Assessment Section
    private var cognitiveAssessmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cognitive Assessment")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let latestAssessment = healthTracker.cognitiveAssessments.first {
                VStack(spacing: 12) {
                    CognitiveScoreRow(
                        title: "Memory",
                        score: latestAssessment.memoryScore,
                        color: latestAssessment.memoryScore >= 80 ? .green : latestAssessment.memoryScore >= 60 ? .yellow : .red
                    )
                    
                    CognitiveScoreRow(
                        title: "Attention",
                        score: latestAssessment.attentionScore,
                        color: latestAssessment.attentionScore >= 80 ? .green : latestAssessment.attentionScore >= 60 ? .yellow : .red
                    )
                    
                    CognitiveScoreRow(
                        title: "Language",
                        score: latestAssessment.languageScore,
                        color: latestAssessment.languageScore >= 80 ? .green : latestAssessment.languageScore >= 60 ? .yellow : .red
                    )
                    
                    CognitiveScoreRow(
                        title: "Executive Function",
                        score: latestAssessment.executiveScore,
                        color: latestAssessment.executiveScore >= 80 ? .green : latestAssessment.executiveScore >= 60 ? .yellow : .red
                    )
                }
            } else {
                Text("No recent cognitive assessments available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Medication Tracking Section
    private var medicationTrackingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Medication Tracking")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(healthTracker.medicationHistory) { medication in
                    MedicationRow(medication: medication)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Sleep Analysis Section
    private var sleepAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Analysis")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let latestSleep = healthTracker.sleepData.first {
                VStack(spacing: 12) {
                    SleepMetricRow(
                        title: "Sleep Duration",
                        value: "\(String(format: "%.1f", latestSleep.hours)) hours",
                        color: latestSleep.hours >= 7 ? .green : latestSleep.hours >= 6 ? .yellow : .red
                    )
                    
                    SleepMetricRow(
                        title: "Sleep Quality",
                        value: "\(latestSleep.quality)/10",
                        color: latestSleep.quality >= 8 ? .green : latestSleep.quality >= 6 ? .yellow : .red
                    )
                    
                    SleepMetricRow(
                        title: "Deep Sleep",
                        value: "\(String(format: "%.1f", latestSleep.deepSleep)) hours",
                        color: latestSleep.deepSleep >= 1.5 ? .green : latestSleep.deepSleep >= 1.0 ? .yellow : .red
                    )
                }
            } else {
                Text("No recent sleep data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Memory Lane View
    private var memoryLaneView: some View {
        MemoryLaneView()
    }
    
    // MARK: - AI Support View
    private var aiSupportView: some View {
        AIChatView()
    }
    
    // MARK: - Doctor Reports View
    private var doctorReportsView: some View {
        DoctorReportsView()
    }
    
    // MARK: - Helper Properties
    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Night"
        }
    }
    
    // MARK: - Actions
    private func triggerEmergencyCall() {
        // Implement VAPI emergency call
        Task {
            await callEmergencyService()
        }
    }
    
    private func callEmergencyService() async {
        // Call the emergency server
        guard let url = URL(string: "https://lovedones-emergency-calling-6db36c5e88ab.herokuapp.com/emergency-call") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{}".utf8)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("Emergency call initiated: \(httpResponse.statusCode)")
            }
        } catch {
            print("Emergency call failed: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// StatCard is defined in AdvancedReminderViews.swift

// ActivityRow is defined in AdvancedReminderViews.swift

struct CaregiverActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .foregroundColor(activity.color)
                .font(.headline)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(activity.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if activity.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.headline)
            } else {
                Circle()
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AlertRow: View {
    let alert: AlertItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.icon)
                .foregroundColor(alert.color)
                .font(.headline)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(alert.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(alert.time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Data Models

struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let icon: String
    let color: Color
    let isCompleted: Bool
}

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let time: String
    let icon: String
    let color: Color
}

// MARK: - Supporting Views

// HealthMetricCard is defined in HealthDashboardView.swift

struct CognitiveScoreRow: View {
    let title: String
    let score: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(score)%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, 4)
    }
}

struct MedicationRow: View {
    let medication: MedicationEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(medication.dosage) at \(medication.time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: medication.taken ? "checkmark.circle.fill" : "circle")
                .foregroundColor(medication.taken ? .green : .gray)
                .font(.title3)
        }
        .padding(.vertical, 8)
    }
}

struct SleepMetricRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Helper Functions
extension CaregiverDashboard {
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private func syncData() {
        isSyncing = true
        
        // Simulate data sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSyncing = false
            lastSyncTime = Date()
            
            // Update health data to match patient dashboard
            healthTracker.syncWithPatientData()
        }
    }
}

// MARK: - Preview

struct CaregiverDashboard_Previews: PreviewProvider {
    static var previews: some View {
        CaregiverDashboard()
    }
}
