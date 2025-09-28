//
//  HealthKitPermissionView.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/28/25.
//

import SwiftUI
import HealthKit

struct HealthKitPermissionView: View {
    @ObservedObject var healthManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Connect Health App")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Allow LovedOnes to read your health data to provide personalized insights and reminders.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Benefits List
                VStack(alignment: .leading, spacing: 16) {
                    BenefitRow(
                        icon: "figure.walk",
                        title: "Step Tracking",
                        description: "Monitor daily activity and set goals"
                    )
                    
                    BenefitRow(
                        icon: "heart.fill",
                        title: "Heart Rate Monitoring",
                        description: "Track heart rate trends and alerts"
                    )
                    
                    BenefitRow(
                        icon: "bed.double.fill",
                        title: "Sleep Analysis",
                        description: "Analyze sleep patterns and quality"
                    )
                    
                    BenefitRow(
                        icon: "stethoscope",
                        title: "Health Metrics",
                        description: "Monitor blood pressure and vital signs"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Privacy Notice
                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy & Security")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Your health data stays on your device and is never shared without your permission. We use this information only to provide personalized health insights and reminders.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        healthManager.requestAuthorization()
                    }) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text("Enable Health Integration")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Skip for Now")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Health Integration")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: healthManager.isAuthorized) { isAuthorized in
                if isAuthorized {
                    dismiss()
                }
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    HealthKitPermissionView(healthManager: HealthKitManager())
}

