//
//  AdvancedReminderViews.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/27/25.
//  🚀 ADVANCED REMINDER VIEWS - LEGENDARY FEATURES
//

import SwiftUI

// MARK: - 📊 DASHBOARD VIEW
struct DashboardView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: LovedOnesDesignSystem.spaceL) {
                // Quick Stats Cards
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
            .padding(LovedOnesDesignSystem.spaceL)
        }
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            Text("Quick Stats")
                .font(LovedOnesDesignSystem.subheadingFont)
                .foregroundColor(viewModel.isDarkMode ? .white : LovedOnesDesignSystem.textPrimary)
                .accessibilityAddTraits(.isHeader)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: LovedOnesDesignSystem.spaceM) {
                StatCard(
                    title: "Today",
                    value: "\(viewModel.todaysReminders().count)",
                    subtitle: "reminders",
                    color: LovedOnesDesignSystem.primaryRed,
                    icon: "sun.max.fill"
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(viewModel.reminders.filter { $0.isCompleted }.count)",
                    subtitle: "tasks",
                    color: LovedOnesDesignSystem.successGreen,
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "Overdue",
                    value: "\(viewModel.reminders.filter { $0.isOverdue }.count)",
                    subtitle: "urgent",
                    color: LovedOnesDesignSystem.dangerRed,
                    icon: "exclamationmark.triangle.fill"
                )
                
                StatCard(
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
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            Text("Today's Overview")
                .font(LovedOnesDesignSystem.subheadingFont)
                .foregroundColor(viewModel.isDarkMode ? .white : LovedOnesDesignSystem.textPrimary)
                .accessibilityAddTraits(.isHeader)
            
            if viewModel.todaysReminders().isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "All caught up!",
                    subtitle: "No reminders for today"
                )
            } else {
                ForEach(viewModel.todaysReminders().prefix(3)) { reminder in
                    CompactReminderCard(reminder: reminder, viewModel: viewModel)
                }
                
                if viewModel.todaysReminders().count > 3 {
                    Button("View All Today's Reminders") {
                        // Navigate to today view
                    }
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(LovedOnesDesignSystem.primaryRed)
                }
            }
        }
    }
    
    private var smartSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            Text("Smart Suggestions")
                .font(LovedOnesDesignSystem.subheadingFont)
                .foregroundColor(viewModel.isDarkMode ? .white : LovedOnesDesignSystem.textPrimary)
                .accessibilityAddTraits(.isHeader)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LovedOnesDesignSystem.spaceM) {
                    ForEach(viewModel.suggestedReminders.prefix(5), id: \.self) { suggestion in
                        SuggestionCard(suggestion: suggestion) {
                            // Create reminder from suggestion
                        }
                    }
                }
                .padding(.horizontal, LovedOnesDesignSystem.spaceL)
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            Text("Recent Activity")
                .font(LovedOnesDesignSystem.subheadingFont)
                .foregroundColor(viewModel.isDarkMode ? .white : LovedOnesDesignSystem.textPrimary)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: LovedOnesDesignSystem.spaceS) {
                ForEach(viewModel.reminders.filter { $0.isCompleted }.prefix(3)) { reminder in
                    ActivityRow(reminder: reminder)
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            Text("Quick Actions")
                .font(LovedOnesDesignSystem.subheadingFont)
                .foregroundColor(viewModel.isDarkMode ? .white : LovedOnesDesignSystem.textPrimary)
                .accessibilityAddTraits(.isHeader)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: LovedOnesDesignSystem.spaceM) {
                ReminderQuickActionCard(
                    title: "Voice Note",
                    icon: "mic.fill",
                    color: LovedOnesDesignSystem.infoBlue
                ) {
                    viewModel.showingVoiceInput = true
                }
                
                ReminderQuickActionCard(
                    title: "Quick Add",
                    icon: "plus.circle.fill",
                    color: LovedOnesDesignSystem.primaryRed
                ) {
                    viewModel.showingAddReminder = true
                }
                
                ReminderQuickActionCard(
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

// MARK: - 📊 STAT CARD
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceS) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(LovedOnesDesignSystem.heroFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(LovedOnesDesignSystem.darkGray)
                
                Text(subtitle)
                    .font(LovedOnesDesignSystem.captionFont)
                    .foregroundColor(LovedOnesDesignSystem.mediumGray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(LovedOnesDesignSystem.spaceM)
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
}

// MARK: - 📝 COMPACT REMINDER CARD
struct CompactReminderCard: View {
    let reminder: Reminder
    @ObservedObject var viewModel: CalendarReminderViewModel
    
    var body: some View {
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
                    .frame(width: 40, height: 40)
                
                Image(systemName: reminder.type.icon)
                    .font(.title3)
                    .foregroundColor(reminder.type.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(reminder.isCompleted ? LovedOnesDesignSystem.darkGray : LovedOnesDesignSystem.textPrimary)
                    .strikethrough(reminder.isCompleted)
                    .lineLimit(1)
                
                Text(formatTime(reminder.combinedDateTime))
                    .font(LovedOnesDesignSystem.captionFont)
                    .foregroundColor(LovedOnesDesignSystem.primaryRed)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // Priority Indicator
            Image(systemName: reminder.priority.icon)
                .font(.caption)
                .foregroundColor(reminder.priority.color)
        }
        .padding(LovedOnesDesignSystem.spaceM)
        .background(
            RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM)
                .fill(LovedOnesDesignSystem.pureWhite)
                .shadow(
                    color: LovedOnesDesignSystem.shadowLight.color,
                    radius: LovedOnesDesignSystem.shadowLight.radius,
                    x: LovedOnesDesignSystem.shadowLight.x,
                    y: LovedOnesDesignSystem.shadowLight.y
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

// MARK: - 💡 SUGGESTION CARD
struct SuggestionCard: View {
    let suggestion: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceS) {
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
                    .font(LovedOnesDesignSystem.captionFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding(LovedOnesDesignSystem.spaceM)
            .frame(width: 150, height: 80)
            .background(
                RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM)
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
    }
}

// MARK: - 📈 ACTIVITY ROW
struct ActivityRow: View {
    let reminder: Reminder
    
    var body: some View {
        HStack(spacing: LovedOnesDesignSystem.spaceM) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundColor(LovedOnesDesignSystem.successGreen)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    .lineLimit(1)
                
                Text("Completed \(formatTimeAgo(reminder.completionDate ?? Date()))")
                    .font(LovedOnesDesignSystem.captionFont)
                    .foregroundColor(LovedOnesDesignSystem.darkGray)
            }
            
            Spacer()
        }
        .padding(.vertical, LovedOnesDesignSystem.spaceS)
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

// MARK: - ⚡ REMINDER QUICK ACTION CARD
struct ReminderQuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: LovedOnesDesignSystem.spaceS) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(LovedOnesDesignSystem.captionFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(LovedOnesDesignSystem.spaceM)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM)
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
    }
}

// MARK: - 📊 STATISTICS VIEW
struct StatisticsView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: LovedOnesDesignSystem.spaceL) {
                    // Overview Stats
                    overviewStatsSection
                    
                    // Completion Rate Chart
                    completionRateSection
                    
                    // Productivity Insights
                    productivitySection
                    
                    // Type Distribution
                    typeDistributionSection
                }
                .padding(LovedOnesDesignSystem.spaceL)
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
    
    private var overviewStatsSection: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            Text("Overview")
                .font(LovedOnesDesignSystem.subheadingFont)
                .foregroundColor(LovedOnesDesignSystem.textPrimary)
                .accessibilityAddTraits(.isHeader)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: LovedOnesDesignSystem.spaceM) {
                StatCard(
                    title: "Total",
                    value: "\(viewModel.reminders.count)",
                    subtitle: "reminders",
                    color: LovedOnesDesignSystem.primaryRed,
                    icon: "list.bullet"
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(viewModel.reminders.filter { $0.isCompleted }.count)",
                    subtitle: "tasks",
                    color: LovedOnesDesignSystem.successGreen,
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "Completion Rate",
                    value: "\(Int(viewModel.completionRate * 100))%",
                    subtitle: "success",
                    color: LovedOnesDesignSystem.infoBlue,
                    icon: "chart.pie.fill"
                )
                
                StatCard(
                    title: "Current Streak",
                    value: "\(viewModel.streakCount)",
                    subtitle: "days",
                    color: LovedOnesDesignSystem.warningOrange,
                    icon: "flame.fill"
                )
            }
        }
    }
    
    private var completionRateSection: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            Text("Completion Rate")
                .font(LovedOnesDesignSystem.subheadingFont)
                .foregroundColor(LovedOnesDesignSystem.textPrimary)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: LovedOnesDesignSystem.spaceM) {
                ProgressView(value: viewModel.completionRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: LovedOnesDesignSystem.primaryRed))
                    .scaleEffect(x: 1, y: 3, anchor: .center)
                    .cornerRadius(LovedOnesDesignSystem.radiusS)
                
                HStack {
                    Text("\(Int(viewModel.completionRate * 100))% Complete")
                        .font(LovedOnesDesignSystem.bodyFont)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    
                    Spacer()
                    
                    Text("\(viewModel.reminders.filter { $0.isCompleted }.count) of \(viewModel.reminders.count)")
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                }
            }
            .padding(LovedOnesDesignSystem.spaceM)
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
    }
    
    private var productivitySection: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            Text("Productivity Insights")
                .font(LovedOnesDesignSystem.subheadingFont)
                .foregroundColor(LovedOnesDesignSystem.textPrimary)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: LovedOnesDesignSystem.spaceM) {
                InsightRow(
                    icon: "clock.fill",
                    title: "Most Productive Hour",
                    value: "\(viewModel.mostProductiveHour):00",
                    color: LovedOnesDesignSystem.successGreen
                )
                
                InsightRow(
                    icon: "timer",
                    title: "Average Completion Time",
                    value: formatDuration(viewModel.averageCompletionTime),
                    color: LovedOnesDesignSystem.infoBlue
                )
                
                InsightRow(
                    icon: "calendar.badge.clock",
                    title: "Recurring Tasks",
                    value: "\(viewModel.reminders.filter { $0.isRecurring }.count)",
                    color: LovedOnesDesignSystem.warningOrange
                )
            }
            .padding(LovedOnesDesignSystem.spaceM)
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
    }
    
    private var typeDistributionSection: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            Text("Task Types")
                .font(LovedOnesDesignSystem.subheadingFont)
                .foregroundColor(LovedOnesDesignSystem.textPrimary)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: LovedOnesDesignSystem.spaceS) {
                ForEach(ReminderType.allCases, id: \.self) { type in
                    let count = viewModel.reminders.filter { $0.type == type }.count
                    if count > 0 {
                        TypeDistributionRow(type: type, count: count, total: viewModel.reminders.count)
                    }
                }
            }
            .padding(LovedOnesDesignSystem.spaceM)
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
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - 💡 INSIGHT ROW
struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: LovedOnesDesignSystem.spaceM) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(LovedOnesDesignSystem.bodyFont)
                .foregroundColor(LovedOnesDesignSystem.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(LovedOnesDesignSystem.bodyFont)
                .foregroundColor(LovedOnesDesignSystem.darkGray)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - 📊 TYPE DISTRIBUTION ROW
struct TypeDistributionRow: View {
    let type: ReminderType
    let count: Int
    let total: Int
    
    private var percentage: Double {
        return total > 0 ? Double(count) / Double(total) : 0
    }
    
    var body: some View {
        HStack(spacing: LovedOnesDesignSystem.spaceM) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(type.color)
                .frame(width: 24)
            
            Text(type.displayName)
                .font(LovedOnesDesignSystem.bodyFont)
                .foregroundColor(LovedOnesDesignSystem.textPrimary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(count)")
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(LovedOnesDesignSystem.darkGray)
                    .fontWeight(.semibold)
                
                Text("\(Int(percentage * 100))%")
                    .font(LovedOnesDesignSystem.captionFont)
                    .foregroundColor(LovedOnesDesignSystem.mediumGray)
            }
        }
    }
}

// MARK: - 🎤 VOICE INPUT VIEW
struct VoiceInputView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: LovedOnesDesignSystem.spaceXL) {
                Spacer()
                
                // Voice Recording Animation
                ZStack {
                    Circle()
                        .fill(LovedOnesDesignSystem.primaryRed.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .scaleEffect(viewModel.isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: viewModel.isRecording)
                    
                    Circle()
                        .fill(LovedOnesDesignSystem.primaryRed)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                // Voice Text
                if !viewModel.voiceText.isEmpty {
                    VStack(spacing: LovedOnesDesignSystem.spaceM) {
                        Text("You said:")
                            .font(LovedOnesDesignSystem.bodyFont)
                            .foregroundColor(LovedOnesDesignSystem.darkGray)
                        
                        Text(viewModel.voiceText)
                            .font(LovedOnesDesignSystem.subheadingFont)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(LovedOnesDesignSystem.spaceM)
                            .background(
                                RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM)
                                    .fill(LovedOnesDesignSystem.warmGray)
                            )
                    }
                }
                
                Spacer()
                
                // Control Buttons
                HStack(spacing: LovedOnesDesignSystem.spaceL) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(LovedOnesDesignSystem.darkGray)
                    
                    Button(viewModel.isRecording ? "Stop" : "Start Recording") {
                        if viewModel.isRecording {
                            viewModel.stopVoiceRecording()
                        } else {
                            viewModel.startVoiceRecording()
                        }
                    }
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, LovedOnesDesignSystem.spaceL)
                    .padding(.vertical, LovedOnesDesignSystem.spaceM)
                    .background(
                        RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM)
                            .fill(LovedOnesDesignSystem.primaryRed)
                    )
                    
                    if !viewModel.voiceText.isEmpty {
                        Button("Create") {
                            viewModel.createReminderFromVoice()
                            dismiss()
                        }
                        .font(LovedOnesDesignSystem.bodyFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, LovedOnesDesignSystem.spaceL)
                        .padding(.vertical, LovedOnesDesignSystem.spaceM)
                        .background(
                            RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusM)
                                .fill(LovedOnesDesignSystem.successGreen)
                        )
                    }
                }
            }
            .padding(LovedOnesDesignSystem.spaceL)
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

// MARK: - ⚙️ SETTINGS VIEW
struct SettingsView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Appearance") {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(LovedOnesDesignSystem.darkGray)
                        
                        Text("Dark Mode")
                        
                        Spacer()
                        
                        Toggle("", isOn: $viewModel.isDarkMode)
                    }
                }
                
                Section("Notifications") {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                        
                        Text("Enable Notifications")
                        
                        Spacer()
                        
                        Toggle("", isOn: $viewModel.notificationPermissionGranted)
                    }
                }
                
                Section("Data") {
                    Button("Export Reminders") {
                        // Export functionality
                    }
                    
                    Button("Import Reminders") {
                        // Import functionality
                    }
                    
                    Button("Clear Completed Tasks", role: .destructive) {
                        // Clear completed tasks
                    }
                }
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

// MARK: - 📅 ENHANCED CALENDAR VIEW
struct EnhancedCalendarView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    
    var body: some View {
        VStack {
            Text("Enhanced Calendar View")
                .font(.title)
                .padding()
            
            Text("Coming Soon - Advanced Calendar Features")
                .foregroundColor(.gray)
        }
    }
}

// MARK: - ☀️ ENHANCED TODAY VIEW
struct EnhancedTodayView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    
    var body: some View {
        VStack {
            Text("Enhanced Today View")
                .font(.title)
                .padding()
            
            Text("Coming Soon - Smart Today Features")
                .foregroundColor(.gray)
        }
    }
}

// MARK: - ⏰ ENHANCED UPCOMING VIEW
struct EnhancedUpcomingView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    
    var body: some View {
        VStack {
            Text("Enhanced Upcoming View")
                .font(.title)
                .padding()
            
            Text("Coming Soon - Smart Upcoming Features")
                .foregroundColor(.gray)
        }
    }
}

// MARK: - ➕ ADVANCED ADD REMINDER VIEW
struct AdvancedAddReminderView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Advanced Add Reminder")
                    .font(.title)
                    .padding()
                
                Text("Coming Soon - Advanced Reminder Creation")
                    .foregroundColor(.gray)
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

// MARK: - ✏️ ADVANCED EDIT REMINDER VIEW
struct AdvancedEditReminderView: View {
    let reminder: Reminder
    @ObservedObject var viewModel: CalendarReminderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Advanced Edit Reminder")
                    .font(.title)
                    .padding()
                
                Text("Coming Soon - Advanced Reminder Editing")
                    .foregroundColor(.gray)
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
