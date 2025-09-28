//
//  EmergencyCallingService.swift
//  lovedones
//
//  Created by Krishna Bhatnagar on 9/28/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - 🚨 EMERGENCY CALL MODELS
struct EmergencyCallRequest: Codable {
    let location: String?
    let timestamp: Date
}

// Data models are defined in HackathonWinningDashboard.swift

// MARK: - 📞 EMERGENCY CALLING SERVICE
class EmergencyCallingService: ObservableObject {
    @Published var isCalling = false
    @Published var lastCallStatus: String?
    @Published var errorMessage: String?
    
    private let baseURL = "https://lovedones-emergency-calling-6db36c5e88ab.herokuapp.com" // Updated Heroku URL
    private var cancellables = Set<AnyCancellable>()
    
    func initiateEmergencyCall() async {
        await MainActor.run {
            isCalling = true
            errorMessage = nil
        }
        
        guard let url = URL(string: "\(baseURL)/emergency-call") else {
            await handleError("Invalid Emergency Calling Server URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = EmergencyCallRequest(
            location: getCurrentLocation(),
            timestamp: Date()
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            await handleError("Failed to encode emergency call request: \(error.localizedDescription)")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await handleError("Invalid HTTP response")
                return
            }
            
            if httpResponse.statusCode == 200 {
                let callResponse = try JSONDecoder().decode(EmergencyCallResponse.self, from: data)
                await MainActor.run {
                    self.lastCallStatus = callResponse.message
                    self.isCalling = false
                }
                
                if callResponse.success {
                    print("🚨 Emergency call initiated successfully!")
                    print("📞 Emergency Phone: \(callResponse.emergency_phone ?? "Unknown")")
                    print("📍 Location: \(callResponse.location?.address ?? "Unknown")")
                    print("📊 Successful Calls: \(callResponse.successful_calls ?? 0)")
                } else {
                    await handleError(callResponse.message ?? "Unknown error")
                }
            } else {
                let responseString = String(data: data, encoding: .utf8) ?? "No response data"
                await handleError("Server error \(httpResponse.statusCode): \(responseString)")
            }
        } catch {
            await handleError("Network request failed: \(error.localizedDescription)")
        }
    }
    
    func testCall() async {
        await MainActor.run {
            isCalling = true
            errorMessage = nil
        }
        
        guard let url = URL(string: "\(baseURL)/test-call") else {
            await handleError("Invalid Emergency Calling Server URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "message": "This is a test call from the LovedOnes app. Everything is working correctly."
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            await handleError("Failed to encode test call request: \(error.localizedDescription)")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await handleError("Invalid HTTP response")
                return
            }
            
            if httpResponse.statusCode == 200 {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let success = jsonResponse["success"] as? Bool,
                   let message = jsonResponse["message"] as? String {
                    await MainActor.run {
                        self.lastCallStatus = message
                        self.isCalling = false
                    }
                    
                    if success {
                        print("✅ Test call initiated successfully!")
                    } else {
                        await handleError(message)
                    }
                } else {
                    await handleError("Invalid response format from server")
                }
            } else {
                let responseString = String(data: data, encoding: .utf8) ?? "No response data"
                await handleError("Server error \(httpResponse.statusCode): \(responseString)")
            }
        } catch {
            await handleError("Network request failed: \(error.localizedDescription)")
        }
    }
    
    private func getCurrentLocation() -> String {
        // In a real app, this would get the actual GPS location
        // For now, return a sample location
        return "123 Maple Street, Atlanta, GA 30309"
    }
    
    private func handleError(_ message: String) async {
        await MainActor.run {
            self.errorMessage = message
            self.isCalling = false
            print("Emergency Calling Error: \(message)")
        }
    }
}

// MARK: - 🚨 EMERGENCY CALL BUTTON VIEW
struct EmergencyCallButton: View {
    @StateObject private var callingService = EmergencyCallingService()
    @State private var showingConfirmation = false
    @State private var showingTestConfirmation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Emergency Call Button
            Button(action: {
                showingConfirmation = true
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.title2)
                    Text("Emergency Call")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(callingService.isCalling)
            
            // Test Call Button
            Button(action: {
                showingTestConfirmation = true
            }) {
                HStack {
                    Image(systemName: "phone.circle.fill")
                        .font(.title3)
                    Text("Test Call")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .disabled(callingService.isCalling)
            
            // Status Messages
            if callingService.isCalling {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Initiating call...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let status = callingService.lastCallStatus {
                Text(status)
                    .font(.caption)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            }
            
            if let error = callingService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .alert("Emergency Call", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Call Caretaker", role: .destructive) {
                Task {
                    await callingService.initiateEmergencyCall()
                }
            }
        } message: {
            Text("This will immediately call your caretaker at +1 404 4238776 with your current location. Only use this in an emergency.")
        }
        .alert("Test Call", isPresented: $showingTestConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Test Call") {
                Task {
                    await callingService.testCall()
                }
            }
        } message: {
            Text("This will make a test call to your caretaker to verify the system is working correctly.")
        }
    }
}

// MARK: - PREVIEW
struct EmergencyCallButton_Previews: PreviewProvider {
    static var previews: some View {
        EmergencyCallButton()
            .padding()
    }
}
