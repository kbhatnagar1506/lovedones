//
//  BeautifulVisualizations.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/27/25.
//  🎨 BEAUTIFUL VISUALIZATIONS - STUNNING CHARTS & GRAPHS
//

import SwiftUI

// MARK: - 📈 METRIC CARD
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    
    enum TrendDirection {
        case up, down, neutral
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceS) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                if trend != .neutral {
                    Image(systemName: trend == .up ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                        .foregroundColor(trend == .up ? LovedOnesDesignSystem.successGreen : LovedOnesDesignSystem.dangerRed)
                }
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(LovedOnesDesignSystem.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(LovedOnesDesignSystem.darkGray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 📊 WEEKLY TREND CHART
struct WeeklyTrendChart: View {
    let data: [Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            Text("Weekly Progress")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(LovedOnesDesignSystem.textPrimary)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<data.count, id: \.self) { index in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LovedOnesDesignSystem.primaryRed)
                            .frame(width: 30, height: max(4, CGFloat(data[index]) * 100))
                            .animation(.easeInOut(duration: 0.6).delay(Double(index) * 0.1), value: data)
                        
                        Text(dayName(for: index))
                            .font(.caption2)
                            .foregroundColor(LovedOnesDesignSystem.darkGray)
                    }
                }
            }
            .frame(height: 120)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    private func dayName(for index: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[index]
    }
}

// MARK: - 🎯 PRIORITY DISTRIBUTION CHART
struct PriorityDistributionChart: View {
    let data: [ReminderPriority: Int]
    
    var body: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            Text("Priority Distribution")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(LovedOnesDesignSystem.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: LovedOnesDesignSystem.spaceS) {
                ForEach(ReminderPriority.allCases, id: \.self) { priority in
                    HStack {
                        Circle()
                            .fill(priorityColor(priority))
                            .frame(width: 12, height: 12)
                        
                        Text(priority.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        
                        Spacer()
                        
                        Text("\(data[priority] ?? 0)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    private func priorityColor(_ priority: ReminderPriority) -> Color {
        switch priority {
        case .urgent: return LovedOnesDesignSystem.dangerRed
        case .high: return LovedOnesDesignSystem.primaryRed
        case .medium: return LovedOnesDesignSystem.warningOrange
        case .low: return LovedOnesDesignSystem.infoBlue
        }
    }
}

// MARK: - 📋 TYPE DISTRIBUTION CHART
struct TypeDistributionChart: View {
    let data: [ReminderType: Int]
    
    var body: some View {
        VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
            Text("Type Distribution")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(LovedOnesDesignSystem.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: LovedOnesDesignSystem.spaceS) {
                ForEach(ReminderType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: typeIcon(type))
                            .font(.subheadline)
                            .foregroundColor(typeColor(type))
                        
                        Text(type.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        
                        Spacer()
                        
                        Text("\(data[type] ?? 0)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    private func typeIcon(_ type: ReminderType) -> String {
        switch type {
        case .medication: return "pills.fill"
        case .appointment: return "calendar"
        case .general: return "bell.fill"
        case .task: return "checklist"
        case .social: return "person.2.fill"
        case .health: return "heart.text.square.fill"
        }
    }
    
    private func typeColor(_ type: ReminderType) -> Color {
        switch type {
        case .medication: return LovedOnesDesignSystem.successGreen
        case .appointment: return LovedOnesDesignSystem.infoBlue
        case .general: return LovedOnesDesignSystem.primaryRed
        case .task: return LovedOnesDesignSystem.warningOrange
        case .social: return LovedOnesDesignSystem.infoBlue
        case .health: return LovedOnesDesignSystem.successGreen
        }
    }
}

// MARK: - 📊 ENHANCED STATISTICS VIEW
struct EnhancedStatisticsView: View {
    @ObservedObject var viewModel: CalendarReminderViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: LovedOnesDesignSystem.spaceL) {
                // Header
                VStack(alignment: .leading, spacing: LovedOnesDesignSystem.spaceM) {
                    Text("Analytics Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    
                    Text("Track your productivity and progress")
                        .font(.subheadline)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Key Metrics Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: LovedOnesDesignSystem.spaceM) {
                    MetricCard(
                        title: "Completion Rate",
                        value: "\(Int(viewModel.completionRate * 100))%",
                        icon: "chart.pie.fill",
                        color: LovedOnesDesignSystem.primaryRed,
                        trend: viewModel.completionRate > 0.7 ? .up : .down
                    )
                    
                    MetricCard(
                        title: "Total Reminders",
                        value: "\(viewModel.totalReminders)",
                        icon: "list.bullet",
                        color: LovedOnesDesignSystem.infoBlue,
                        trend: .neutral
                    )
                    
                    MetricCard(
                        title: "Completed Today",
                        value: "\(viewModel.completedToday)",
                        icon: "checkmark.circle.fill",
                        color: LovedOnesDesignSystem.successGreen,
                        trend: .up
                    )
                    
                    MetricCard(
                        title: "Overdue",
                        value: "\(viewModel.overdueCount)",
                        icon: "exclamationmark.triangle.fill",
                        color: LovedOnesDesignSystem.warningOrange,
                        trend: viewModel.overdueCount > 0 ? .down : .neutral
                    )
                }
                
                // Charts Section
                VStack(spacing: LovedOnesDesignSystem.spaceL) {
                    // Weekly Trend Chart
                    WeeklyTrendChart(data: viewModel.weeklyTrend)
                    
                    // Priority Distribution
                    PriorityDistributionChart(data: viewModel.priorityDistribution)
                    
                    // Type Distribution
                    TypeDistributionChart(data: viewModel.typeDistribution)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.calculateAnalytics()
        }
    }
}

// MARK: - 🎨 ANIMATED FILTER CHIP
struct AnimatedFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : LovedOnesDesignSystem.primaryRed)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : LovedOnesDesignSystem.primaryRed)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? LovedOnesDesignSystem.primaryRed : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(LovedOnesDesignSystem.primaryRed, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - 🌟 BEAUTIFUL REMINDER CARD
struct BeautifulReminderCard: View {
    let reminder: Reminder
    let onToggle: () -> Void
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: LovedOnesDesignSystem.spaceM) {
                // Priority Indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(priorityColor)
                    .frame(width: 4)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(reminder.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(LovedOnesDesignSystem.textPrimary)
                            .strikethrough(reminder.isCompleted)
                        
                        Spacer()
                        
                        if reminder.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(LovedOnesDesignSystem.successGreen)
                                .font(.title3)
                        }
                    }
                    
                    Text(reminder.description)
                        .font(.subheadline)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                        .lineLimit(2)
                    
                    HStack {
                        // Type Badge
                        HStack(spacing: 4) {
                            Image(systemName: typeIcon)
                                .font(.caption)
                            Text(reminder.type.rawValue.capitalized)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(typeColor.opacity(0.2))
                        )
                        .foregroundColor(typeColor)
                        
                        Spacer()
                        
                        // Time
                        Text(timeString)
                            .font(.caption)
                            .foregroundColor(LovedOnesDesignSystem.darkGray)
                    }
                }
                
                // Toggle Button
                Button(action: onToggle) {
                    Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(reminder.isCompleted ? LovedOnesDesignSystem.successGreen : LovedOnesDesignSystem.mediumGray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var priorityColor: Color {
        switch reminder.priority {
        case .urgent: return LovedOnesDesignSystem.dangerRed
        case .high: return LovedOnesDesignSystem.primaryRed
        case .medium: return LovedOnesDesignSystem.warningOrange
        case .low: return LovedOnesDesignSystem.infoBlue
        }
    }
    
    private var typeIcon: String {
        switch reminder.type {
        case .medication: return "pills.fill"
        case .appointment: return "calendar"
        case .general: return "bell.fill"
        case .task: return "checklist"
        case .social: return "person.2.fill"
        case .health: return "heart.text.square.fill"
        }
    }
    
    private var typeColor: Color {
        switch reminder.type {
        case .medication: return LovedOnesDesignSystem.successGreen
        case .appointment: return LovedOnesDesignSystem.infoBlue
        case .general: return LovedOnesDesignSystem.primaryRed
        case .task: return LovedOnesDesignSystem.warningOrange
        case .social: return LovedOnesDesignSystem.infoBlue
        case .health: return LovedOnesDesignSystem.successGreen
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: reminder.combinedDateTime)
    }
}
