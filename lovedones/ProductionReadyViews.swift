//
//  ProductionReadyViews.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/27/25.
//  PRODUCTION-READY SUPPORTING VIEWS
//

import SwiftUI

// MARK: - ⚙️ DASHBOARD SETTINGS VIEW
struct DashboardSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var notificationsEnabled = true
    @State private var hapticFeedbackEnabled = true
    @State private var fontSize: CGFloat = 16
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Preferences") {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                        Toggle("Notifications", isOn: $notificationsEnabled)
                    }
                    
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                        Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
                    }
                    
                    HStack {
                        Image(systemName: "textformat.size")
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                        VStack(alignment: .leading) {
                            Text("Font Size")
                            Slider(value: $fontSize, in: 12...24, step: 2)
                        }
                    }
                }
                
                Section("Account") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                        Text("Profile Settings")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                        Text("Privacy & Security")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                
                Section("Support") {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                        Text("Help & Support")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(LovedOnesDesignSystem.primaryRed)
                        Text("Contact Us")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button("Sign Out") {
                        showingLogoutAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                // Handle sign out
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - 🔔 NOTIFICATIONS VIEW
struct NotificationsView: View {
    let notifications: [DashboardNotification]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(notifications) { notification in
                    NotificationRow(notification: notification)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 📱 NOTIFICATION ROW
struct NotificationRow: View {
    let notification: DashboardNotification
    
    var body: some View {
        HStack(spacing: LovedOnesDesignSystem.spaceM) {
            Circle()
                .fill(notificationColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(LovedOnesDesignSystem.bodyFont)
                    .foregroundColor(LovedOnesDesignSystem.textPrimary)
                    .fontWeight(notification.isRead ? .regular : .semibold)
                
                Text(notification.message)
                    .font(LovedOnesDesignSystem.captionFont)
                    .foregroundColor(LovedOnesDesignSystem.darkGray)
                    .lineLimit(2)
                
                Text(timeAgoString(from: notification.timestamp))
                    .font(LovedOnesDesignSystem.smallFont)
                    .foregroundColor(LovedOnesDesignSystem.darkGray)
            }
            
            Spacer()
            
            if !notification.isRead {
                Circle()
                    .fill(LovedOnesDesignSystem.primaryRed)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var notificationColor: Color {
        switch notification.type {
        case .task: return LovedOnesDesignSystem.primaryRed
        case .safety: return LovedOnesDesignSystem.successGreen
        case .family: return LovedOnesDesignSystem.infoBlue
        case .system: return LovedOnesDesignSystem.warningOrange
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) min ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}

#Preview {
    DashboardSettingsView()
}
