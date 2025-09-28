//
//  FamilyContactsView.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/27/25.
//

import SwiftUI
import Foundation

// MARK: - Family Contact Model
struct FamilyContact: Identifiable, Codable {
    let id = UUID()
    let name: String
    let phone: String
    let relationship: String
    let priority: Int
    let lastCalled: String?
    let callCount: Int
    
    enum CodingKeys: String, CodingKey {
        case name, phone, relationship, priority
        case lastCalled = "last_called"
        case callCount = "call_count"
    }
}

// MARK: - Family Contacts Manager
class FamilyContactsManager: ObservableObject {
    @Published var contacts: [FamilyContact] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let serverURL = "https://lovedones-emergency-calling-6db36c5e88ab.herokuapp.com"
    
    func loadContacts() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let contacts = try await fetchContacts()
                await MainActor.run {
                    self.contacts = contacts
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load contacts: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func fetchContacts() async throws -> [FamilyContact] {
        guard let url = URL(string: "\(serverURL)/family-contacts") else {
            throw NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }
        
        let serverResponse = try JSONDecoder().decode(ServerResponse.self, from: data)
        
        guard serverResponse.success else {
            throw NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: serverResponse.message ?? "Failed to fetch contacts"])
        }
        
        return serverResponse.contacts
    }
    
    func addContact(name: String, phone: String, relationship: String, priority: Int = 1) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await addContactToServer(name: name, phone: phone, relationship: relationship, priority: priority)
                await MainActor.run {
                    self.loadContacts() // Reload contacts
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to add contact: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func addContactToServer(name: String, phone: String, relationship: String, priority: Int) async throws {
        guard let url = URL(string: "\(serverURL)/family-contacts") else {
            throw NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let contactData = [
            "name": name,
            "phone": phone,
            "relationship": relationship,
            "priority": priority
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: contactData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }
        
        let serverResponse = try JSONDecoder().decode(ServerResponse.self, from: data)
        
        guard serverResponse.success else {
            throw NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: serverResponse.message ?? "Failed to add contact"])
        }
    }
    
    func removeContact(phone: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await removeContactFromServer(phone: phone)
                await MainActor.run {
                    self.loadContacts() // Reload contacts
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to remove contact: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func removeContactFromServer(phone: String) async throws {
        guard let url = URL(string: "\(serverURL)/family-contacts/\(phone)") else {
            throw NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }
    }
}

// MARK: - Server Response Model
struct ServerResponse: Codable {
    let success: Bool
    let message: String?
    let contacts: [FamilyContact]
    let count: Int?
    
    enum CodingKeys: String, CodingKey {
        case success, message, contacts, count
    }
}

// MARK: - Family Contacts View
struct FamilyContactsView: View {
    @StateObject private var contactsManager = FamilyContactsManager()
    @State private var showingAddContact = false
    
    var body: some View {
        NavigationView {
            VStack {
                if contactsManager.isLoading {
                    ProgressView("Loading contacts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if contactsManager.contacts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Family Contacts")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        
                        Text("Add family members who should be called in emergencies")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button("Add First Contact") {
                            showingAddContact = true
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(contactsManager.contacts) { contact in
                            FamilyContactRow(contact: contact) {
                                contactsManager.removeContact(phone: contact.phone)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Family Contacts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddContact = true
                    }
                }
            }
            .sheet(isPresented: $showingAddContact) {
                AddFamilyContactView { name, phone, relationship, priority in
                    contactsManager.addContact(name: name, phone: phone, relationship: relationship, priority: priority)
                    showingAddContact = false
                }
            }
            .alert("Error", isPresented: .constant(contactsManager.errorMessage != nil)) {
                Button("OK") {
                    contactsManager.errorMessage = nil
                }
            } message: {
                if let error = contactsManager.errorMessage {
                    Text(error)
                }
            }
        }
        .onAppear {
            contactsManager.loadContacts()
        }
    }
}

// MARK: - Family Contact Row
struct FamilyContactRow: View {
    let contact: FamilyContact
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(contact.relationship)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(contact.phone)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                HStack {
                    Text("Priority: \(contact.priority)")
                        .font(.caption2)
                        .foregroundColor(priorityColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.2))
                        .cornerRadius(4)
                    
                    if contact.callCount > 0 {
                        Text("Called \(contact.callCount) times")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var priorityColor: Color {
        switch contact.priority {
        case 1: return .red
        case 2: return .orange
        default: return .green
        }
    }
}

// MARK: - Add Family Contact View
struct AddFamilyContactView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var relationship = ""
    @State private var priority = 1
    
    let onSave: (String, String, String, Int) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contact Information") {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Relationship", text: $relationship)
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        Text("High (1)").tag(1)
                        Text("Medium (2)").tag(2)
                        Text("Low (3)").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button("Save Contact") {
                        onSave(name, phone, relationship, priority)
                    }
                    .disabled(name.isEmpty || phone.isEmpty || relationship.isEmpty)
                }
            }
            .navigationTitle("Add Family Contact")
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

#Preview {
    FamilyContactsView()
}
