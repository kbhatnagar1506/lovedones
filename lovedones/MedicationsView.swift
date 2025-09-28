//
//  MedicationsView.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/28/25.
//

import SwiftUI

struct MedicationsView: View {
    @ObservedObject var healthManager: HealthKitManager
    @State private var showingAddMedication = false
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Search Bar
            searchBar
            
            // Medications List
            medicationsList
        }
        .navigationTitle("Medications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddMedication = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView(healthManager: healthManager)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Medication Tracker")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Stay on top of your medications")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(activeMedications.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick Stats
            HStack(spacing: 16) {
                StatCard(
                    title: "Due Today",
                    value: "\(medicationsDueToday.count)",
                    subtitle: "Medications",
                    color: .orange,
                    icon: "clock.fill"
                )
                
                StatCard(
                    title: "Taken Today",
                    value: "\(medicationsTakenToday.count)",
                    subtitle: "Completed",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "Missed",
                    value: "\(missedMedications.count)",
                    subtitle: "Overdue",
                    color: .red,
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search medications...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Medications List
    private var medicationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Due Today Section
                if !medicationsDueToday.isEmpty {
                    SectionHeader(title: "Due Today", count: medicationsDueToday.count)
                    
                    ForEach(medicationsDueToday) { medication in
                        MedicationCard(
                            medication: medication,
                            isDue: true,
                            onTake: {
                                takeMedication(medication)
                            },
                            onSkip: {
                                skipMedication(medication)
                            }
                        )
                    }
                }
                
                // Other Medications
                if !otherMedications.isEmpty {
                    SectionHeader(title: "All Medications", count: otherMedications.count)
                    
                    ForEach(otherMedications) { medication in
                        MedicationCard(
                            medication: medication,
                            isDue: false,
                            onTake: {
                                takeMedication(medication)
                            },
                            onSkip: {
                                skipMedication(medication)
                            }
                        )
                    }
                }
                
                // Empty State
                if healthManager.healthData.medications.isEmpty {
                    MedicationsEmptyStateView()
                }
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    private var activeMedications: [Medication] {
        healthManager.healthData.medications.filter { $0.isActive }
    }
    
    private var medicationsDueToday: [Medication] {
        let calendar = Calendar.current
        let today = Date()
        
        return activeMedications.filter { medication in
            // Check if medication is due today based on time of day
            let timeOfDay = medication.timeOfDay.lowercased()
            let currentHour = calendar.component(.hour, from: today)
            
            switch timeOfDay {
            case "morning":
                return currentHour >= 6 && currentHour < 12
            case "afternoon":
                return currentHour >= 12 && currentHour < 18
            case "evening":
                return currentHour >= 18 && currentHour < 22
            case "night":
                return currentHour >= 22 || currentHour < 6
            default:
                return true
            }
        }
    }
    
    private var medicationsTakenToday: [Medication] {
        let calendar = Calendar.current
        let today = Date()
        
        return activeMedications.filter { medication in
            guard let lastTaken = medication.lastTaken else { return false }
            return calendar.isDate(lastTaken, inSameDayAs: today)
        }
    }
    
    private var missedMedications: [Medication] {
        let calendar = Calendar.current
        let today = Date()
        
        return activeMedications.filter { medication in
            guard let lastTaken = medication.lastTaken else { return true }
            return !calendar.isDate(lastTaken, inSameDayAs: today) && medicationsDueToday.contains { $0.id == medication.id }
        }
    }
    
    private var otherMedications: [Medication] {
        activeMedications.filter { medication in
            !medicationsDueToday.contains { $0.id == medication.id }
        }
    }
    
    private var filteredMedications: [Medication] {
        if searchText.isEmpty {
            return activeMedications
        }
        
        return activeMedications.filter { medication in
            medication.name.localizedCaseInsensitiveContains(searchText) ||
            medication.dosage.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Actions
    private func takeMedication(_ medication: Medication) {
        var updatedMedication = medication
        updatedMedication = Medication(
            name: medication.name,
            dosage: medication.dosage,
            frequency: medication.frequency,
            timeOfDay: medication.timeOfDay,
            isActive: medication.isActive,
            lastTaken: Date()
        )
        healthManager.updateMedication(updatedMedication)
    }
    
    private func skipMedication(_ medication: Medication) {
        // Handle skipping medication
        print("Skipped medication: \(medication.name)")
    }
}

// MARK: - Supporting Views
struct SectionHeader: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
        .padding(.horizontal, 4)
    }
}

struct MedicationCard: View {
    let medication: Medication
    let isDue: Bool
    let onTake: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(medication.dosage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(medication.frequency)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        Text(medication.timeOfDay)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                if isDue {
                    VStack(spacing: 8) {
                        Button(action: onTake) {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Take")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Button(action: onSkip) {
                            Text("Skip")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    VStack(alignment: .trailing) {
                        if let lastTaken = medication.lastTaken {
                            Text("Last taken: \(lastTaken, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Not taken yet")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            // Progress indicator for due medications
            if isDue {
                HStack {
                    Text("Due now")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Text("Take with food if needed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDue ? Color.orange : Color.clear, lineWidth: 2)
        )
    }
}

struct MedicationsEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No Medications Added")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your medications to track them and receive reminders.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Add Medication View
struct AddMedicationView: View {
    @ObservedObject var healthManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = "Once daily"
    @State private var timeOfDay = "Morning"
    
    private let frequencies = ["Once daily", "Twice daily", "Three times daily", "As needed"]
    private let timesOfDay = ["Morning", "Afternoon", "Evening", "Night"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Medication Details") {
                    TextField("Medication Name", text: $name)
                    TextField("Dosage (e.g., 10mg)", text: $dosage)
                }
                
                Section("Schedule") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in
                            Text(freq).tag(freq)
                        }
                    }
                    
                    Picker("Time of Day", selection: $timeOfDay) {
                        ForEach(timesOfDay, id: \.self) { time in
                            Text(time).tag(time)
                        }
                    }
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMedication()
                    }
                    .disabled(name.isEmpty || dosage.isEmpty)
                }
            }
        }
    }
    
    private func saveMedication() {
        let medication = Medication(
            name: name,
            dosage: dosage,
            frequency: frequency,
            timeOfDay: timeOfDay,
            isActive: true,
            lastTaken: nil
        )
        
        healthManager.addMedication(medication)
        dismiss()
    }
}

#Preview {
    MedicationsView(healthManager: HealthKitManager())
}
