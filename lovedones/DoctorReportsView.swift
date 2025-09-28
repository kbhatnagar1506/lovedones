//
//  DoctorReportsView.swift
//  LovedOnes
//
//  Doctor reports and analysis view
//

import SwiftUI
import Charts

struct DoctorReportsView: View {
    @StateObject private var reportGenerator = DoctorReportGenerator()
    @State private var showingReportDetail = false
    @State private var selectedReport: DoctorReport?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Generate Report Button
                    generateReportSection
                    
                    // Reports List
                    reportsListSection
                }
                .padding()
            }
            .navigationTitle("Doctor Reports")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingReportDetail) {
            if let report = selectedReport {
                DoctorReportDetailView(report: report)
            }
        }
    }
    
    private var generateReportSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Generate Reports")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Create comprehensive reports for doctor visits")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Quick Report Button
                Button(action: {
                    Task {
                        await reportGenerator.generateReport()
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.title2)
                        Text("Quick Report")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Standard")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    )
                    .foregroundColor(.blue)
                }
                .disabled(reportGenerator.isGenerating)
                
                // Weekly AI Report Button
                Button(action: {
                    Task {
                        await reportGenerator.generateWeeklyReport()
                    }
                }) {
                    VStack(spacing: 8) {
                        if reportGenerator.isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                        }
                        
                        Text(reportGenerator.isGenerating ? "Generating..." : "AI Weekly Report")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Comprehensive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.pink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(reportGenerator.isGenerating)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    private var reportsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Reports")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Weekly AI Report Section
            if let weeklyReport = reportGenerator.weeklyReport {
                WeeklyReportCard(report: weeklyReport)
            }
            
            if reportGenerator.generatedReports.isEmpty && reportGenerator.weeklyReport == nil {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(reportGenerator.generatedReports) { report in
                        ReportCard(report: report) {
                            selectedReport = report
                            showingReportDetail = true
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Reports Yet")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Generate your first doctor's brief to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct ReportCard: View {
    let report: DoctorReport
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Report for \(report.patientName)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(report.period)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatDate(report.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(report.executiveSummary)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                if !report.topChanges.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Key Changes:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        ForEach(report.topChanges.prefix(2), id: \.self) { change in
                            Text("• \(change)")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                HStack {
                    Label("\(report.medicationCompliance)% Medication Compliance", systemImage: "pills.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Label("\(report.insights.count) Insights", systemImage: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DoctorReportDetailView: View {
    let report: DoctorReport
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Report Section", selection: $selectedTab) {
                    Text("Summary").tag(0)
                    Text("Charts").tag(1)
                    Text("Insights").tag(2)
                    Text("Actions").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    summaryView
                        .tag(0)
                    
                    chartsView
                        .tag(1)
                    
                    insightsView
                        .tag(2)
                    
                    actionsView
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Doctor Report")
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
    
    private var summaryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Executive Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Executive Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(report.executiveSummary)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                
                // Top Changes
                if !report.topChanges.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top 3 Changes")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        ForEach(Array(report.topChanges.enumerated()), id: \.offset) { index, change in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1).")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                    .frame(width: 20, alignment: .leading)
                                
                                Text(change)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                
                // Caregiver Notes
                if !report.caregiverNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Caregiver Notes")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        ForEach(Array(report.caregiverNotes.enumerated()), id: \.offset) { index, note in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.body)
                                    .foregroundColor(.blue)
                                
                                Text(note)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                
                // Conversation Cues
                if !report.conversationCues.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Conversation Cues")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("What to mention to the doctor:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(report.conversationCues) { cue in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cue.cue)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(cue.context)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var chartsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Cognitive Chart
                ChartCard(
                    title: report.cognitiveChart.title,
                    data: report.cognitiveChart.dataPoints,
                    color: report.cognitiveChart.color
                )
                
                // Mood Chart
                ChartCard(
                    title: report.moodChart.title,
                    data: report.moodChart.dataPoints,
                    color: report.moodChart.color
                )
                
                // Sleep Chart
                ChartCard(
                    title: report.sleepChart.title,
                    data: report.sleepChart.dataPoints,
                    color: report.sleepChart.color
                )
            }
            .padding()
        }
    }
    
    private var insightsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(report.insights) { insight in
                    InsightCard(insight: insight)
                }
                
                if report.insights.isEmpty {
                    Text("No significant insights detected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    private var actionsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(report.actionItems) { action in
                    ActionItemCard(action: action)
                }
                
                if report.actionItems.isEmpty {
                    Text("No action items required")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding()
        }
    }
}

struct ChartCard: View {
    let title: String
    let data: [ChartDataPoint]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Simple line chart representation
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(data.suffix(10)) { point in
                    Rectangle()
                        .fill(color)
                        .frame(width: 20, height: max(4, CGFloat(point.value) * 2))
                        .cornerRadius(2)
                }
            }
            .frame(height: 100)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct InsightCard: View {
    let insight: Insight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(insight.severity == .high ? .red : insight.severity == .medium ? .orange : .green)
                    .font(.headline)
                
                Text(insight.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(String(insight.severity.rawValue).capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(insight.severity == .high ? Color.red : insight.severity == .medium ? Color.orange : Color.green)
                    )
            }
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(.primary)
            
            Text(insight.recommendation)
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct ActionItemCard: View {
    let action: ActionItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .foregroundColor(action.priority == .high ? .red : action.priority == .medium ? .orange : .green)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Due: \(formatDate(action.dueDate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(action.priority.rawValue).capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(action.priority == .high ? Color.red : action.priority == .medium ? Color.orange : Color.green)
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Weekly Report Card

struct WeeklyReportCard: View {
    let report: WeeklyReport
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                            .font(.headline)
                        
                        Text("AI Weekly Report")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(formatDate(report.generatedDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(report.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Key Findings
                    if !report.keyFindings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Key Findings")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            ForEach(report.keyFindings.prefix(3), id: \.self) { finding in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text(finding)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Recommendations
                    if !report.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recommendations")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            ForEach(report.recommendations.prefix(3), id: \.self) { recommendation in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text(recommendation)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Full Report Content (truncated)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Report")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(report.content)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(isExpanded ? nil : 3)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            // Share report
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            // Save as PDF
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.fill")
                                Text("Save PDF")
                            }
                            .font(.caption)
                            .foregroundColor(.green)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.05)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .purple.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct DoctorReportsView_Previews: PreviewProvider {
    static var previews: some View {
        DoctorReportsView()
    }
}
