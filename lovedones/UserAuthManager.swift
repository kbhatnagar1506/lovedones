//
//  UserAuthManager.swift
//  LovedOnes
//
//  User authentication and session management
//

import Foundation
import SwiftUI

// MARK: - User Authentication Manager

class UserAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isCaregiver = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiBaseURL = "https://lovedones-app-3d38a08e2be6.herokuapp.com"
    private var session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Authentication Methods
    
    func signUp(name: String, email: String, phone: String?) async {
        print("🔍 Starting sign up for: \(email)")
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let user = try await createUser(name: name, email: email, phone: phone)
            print("🔍 Sign up successful for: \(user.email)")
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.isLoading = false
                print("🔍 UserAuthManager - Sign up: isAuthenticated set to: \(self.isAuthenticated)")
            }
        } catch {
            print("❌ Sign up failed: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                print("🔍 UserAuthManager - Sign up error: errorMessage set to: \(self.errorMessage ?? "nil")")
            }
        }
    }
    
    func signIn(email: String) async {
        print("🔍 Starting sign in for: \(email)")
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let user = try await getUserByEmail(email: email)
            print("🔍 Sign in successful for: \(user.email)")
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.isLoading = false
                print("🔍 UserAuthManager - Sign in: isAuthenticated set to: \(self.isAuthenticated)")
            }
        } catch {
            print("❌ Sign in failed: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                print("🔍 UserAuthManager - Sign in error: errorMessage set to: \(self.errorMessage ?? "nil")")
            }
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        isCaregiver = false
        errorMessage = nil
    }
    
    // MARK: - Quick Login Methods for Demo
    
    func loginAsDavid() {
        let david = User(
            id: "david-patient-001",
            name: "David",
            email: "david@lovedones.com",
            phone: "+1-555-0123",
            createdAt: "2024-01-01T00:00:00Z"
        )
        
        currentUser = david
        isAuthenticated = true
        isCaregiver = false
        errorMessage = nil
    }
    
    func loginAsAlex() {
        let alex = User(
            id: "alex-caregiver-001",
            name: "Alex",
            email: "alex@lovedones.com",
            phone: "+1-555-0124",
            createdAt: "2024-01-01T00:00:00Z"
        )
        
        currentUser = alex
        isAuthenticated = true
        isCaregiver = true
        errorMessage = nil
    }
    
    // MARK: - API Methods
    
    private func createUser(name: String, email: String, phone: String?) async throws -> User {
        let request = UserCreationRequest(name: name, email: email, phone: phone)
        
        guard let url = URL(string: "\(apiBaseURL)/api/users") else {
            throw AuthError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw AuthError.encodingError
        }
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        print("🔍 Auth Response Status: \(httpResponse.statusCode)")
        print("🔍 Auth Response Data: \(String(data: data, encoding: .utf8) ?? "No data")")
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw AuthError.serverError(httpResponse.statusCode)
        }
        
        let responseData = try JSONDecoder().decode(UserCreationResponse.self, from: data)
        return responseData.user
    }
    
    private func getUserByEmail(email: String) async throws -> User {
        print("🔍 Signing in user with email: \(email)")
        
        let request = LoginRequest(email: email)
        
        guard let url = URL(string: "\(apiBaseURL)/api/users/login") else {
            throw AuthError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw AuthError.encodingError
        }
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        print("🔍 Login Response Status: \(httpResponse.statusCode)")
        print("🔍 Login Response Data: \(String(data: data, encoding: .utf8) ?? "No data")")
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw AuthError.userNotFound
            }
            throw AuthError.serverError(httpResponse.statusCode)
        }
        
        let responseData = try JSONDecoder().decode(UserCreationResponse.self, from: data)
        return responseData.user
    }
}

// MARK: - Data Models

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let phone: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, phone
        case createdAt = "created_at"
    }
}

struct UserCreationRequest: Codable {
    let name: String
    let email: String
    let phone: String?
}

struct LoginRequest: Codable {
    let email: String
}

struct UserCreationResponse: Codable {
    let success: Bool
    let user: User
}

// MARK: - Error Types

enum AuthError: LocalizedError {
    case invalidURL
    case encodingError
    case invalidResponse
    case serverError(Int)
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError:
            return "Failed to encode request"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .userNotFound:
            return "User not found. Please sign up first."
        }
    }
}
