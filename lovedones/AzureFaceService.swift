//
//  AzureFaceService.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/27/25.
//

import Foundation
import UIKit
import Vision

// MARK: - Azure Face API Models
struct AzureFaceResponse: Codable {
    let faceId: String
    let faceRectangle: FaceRectangle
    let faceAttributes: FaceAttributes?
}

struct FaceRectangle: Codable {
    let top: Int
    let left: Int
    let width: Int
    let height: Int
}

struct FaceAttributes: Codable {
    let age: Double?
    let gender: String?
    let emotion: Emotion?
}

struct Emotion: Codable {
    let anger: Double?
    let contempt: Double?
    let disgust: Double?
    let fear: Double?
    let happiness: Double?
    let neutral: Double?
    let sadness: Double?
    let surprise: Double?
}

struct PersonGroup: Codable {
    let personGroupId: String
    let name: String
    let userData: String?
}

struct Person: Codable {
    let personId: String
    let name: String
    let userData: String?
}

struct IdentifyResponse: Codable {
    let faceId: String
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let personId: String
    let confidence: Double
}

// MARK: - Face Detection Result
struct FaceDetectionResult {
    let faceId: String?
    let personName: String?
    let confidence: Double
    let faceRectangle: CGRect
    let faceAttributes: FaceAttributes?
}

// MARK: - Azure Face Service
class AzureFaceService: ObservableObject {
    static let shared = AzureFaceService()
    
    // Azure Face API Configuration
    private let endpoint = "https://krishna1234324.cognitiveservices.azure.com/"
    private let subscriptionKey = "YOUR_AZURE_FACE_API_KEY_HERE"
    private let personGroupId = "lovedones-family"
    
    @Published var isInitialized = false
    @Published var familyMembers: [Person] = []
    @Published var errorMessage: String?
    
    private init() {
        setupPersonGroup()
    }
    
    // MARK: - Setup Methods
    func setupPersonGroup() {
        Task {
            do {
                try await createPersonGroupIfNeeded()
                try await loadFamilyMembers()
                await MainActor.run {
                    self.isInitialized = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to setup Azure Face API: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func createPersonGroupIfNeeded() async throws {
        // Check if person group exists
        let url = URL(string: "\(endpoint)face/v1.0/persongroups/\(personGroupId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(subscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Person group exists
                return
            }
        } catch {
            // Person group doesn't exist, create it
        }
        
        // Create person group
        let createURL = URL(string: "\(endpoint)face/v1.0/persongroups/\(personGroupId)")!
        var createRequest = URLRequest(url: createURL)
        createRequest.httpMethod = "PUT"
        createRequest.setValue(subscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "name": "Loved Ones Family",
            "userData": "Family members for memory assistance"
        ]
        
        createRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, createResponse) = try await URLSession.shared.data(for: createRequest)
        guard let httpResponse = createResponse as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "AzureFaceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create person group"])
        }
    }
    
    // MARK: - Face Detection
    func detectFaces(in image: UIImage) async throws -> [FaceDetectionResult] {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "AzureFaceError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let url = URL(string: "\(endpoint)face/v1.0/detect?returnFaceId=true&returnFaceAttributes=age,gender,emotion")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(subscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "AzureFaceError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Face detection failed"])
        }
        
        let faceResponses = try JSONDecoder().decode([AzureFaceResponse].self, from: data)
        
        // Identify faces
        var results: [FaceDetectionResult] = []
        for faceResponse in faceResponses {
            let personName = try await identifyFace(faceId: faceResponse.faceId)
            
            let faceRect = CGRect(
                x: faceResponse.faceRectangle.left,
                y: faceResponse.faceRectangle.top,
                width: faceResponse.faceRectangle.width,
                height: faceResponse.faceRectangle.height
            )
            
            let result = FaceDetectionResult(
                faceId: faceResponse.faceId,
                personName: personName,
                confidence: 0.8, // Default confidence
                faceRectangle: faceRect,
                faceAttributes: faceResponse.faceAttributes
            )
            
            results.append(result)
        }
        
        return results
    }
    
    // MARK: - Face Identification
    private func identifyFace(faceId: String) async throws -> String? {
        let url = URL(string: "\(endpoint)face/v1.0/identify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(subscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "faceIds": [faceId],
            "personGroupId": personGroupId,
            "maxNumOfCandidatesReturned": 1,
            "confidenceThreshold": 0.5
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        let identifyResponses = try JSONDecoder().decode([IdentifyResponse].self, from: data)
        
        guard let identifyResponse = identifyResponses.first,
              let candidate = identifyResponse.candidates.first else {
            return nil
        }
        
        // Get person name
        return try await getPersonName(personId: candidate.personId)
    }
    
    // MARK: - Person Management
    func addFamilyMember(name: String, image: UIImage) async throws {
        // Create person
        let personId = try await createPerson(name: name)
        
        // Add face to person
        try await addFaceToPerson(personId: personId, image: image)
        
        // Train person group
        try await trainPersonGroup()
        
        // Reload family members
        try await loadFamilyMembers()
    }
    
    private func createPerson(name: String) async throws -> String {
        let url = URL(string: "\(endpoint)face/v1.0/persongroups/\(personGroupId)/persons")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(subscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "name": name,
            "userData": "Family member"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "AzureFaceError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create person"])
        }
        
        let personResponse = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        return personResponse["personId"] as! String
    }
    
    private func addFaceToPerson(personId: String, image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "AzureFaceError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let url = URL(string: "\(endpoint)face/v1.0/persongroups/\(personGroupId)/persons/\(personId)/persistedFaces")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(subscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "AzureFaceError", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to add face to person"])
        }
    }
    
    private func trainPersonGroup() async throws {
        let url = URL(string: "\(endpoint)face/v1.0/persongroups/\(personGroupId)/train")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(subscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 202 else {
            throw NSError(domain: "AzureFaceError", code: 7, userInfo: [NSLocalizedDescriptionKey: "Failed to train person group"])
        }
        
        // Wait for training to complete
        try await waitForTrainingCompletion()
    }
    
    private func waitForTrainingCompletion() async throws {
        // Poll training status
        for _ in 0..<30 { // Max 30 attempts
            let url = URL(string: "\(endpoint)face/v1.0/persongroups/\(personGroupId)/training")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(subscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                continue
            }
            
            let trainingStatus = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            let status = trainingStatus["status"] as! String
            
            if status == "succeeded" {
                return
            } else if status == "failed" {
                throw NSError(domain: "AzureFaceError", code: 8, userInfo: [NSLocalizedDescriptionKey: "Training failed"])
            }
            
            // Wait 2 seconds before next check
            try await Task.sleep(nanoseconds: 2_000_000_000)
        }
        
        throw NSError(domain: "AzureFaceError", code: 9, userInfo: [NSLocalizedDescriptionKey: "Training timeout"])
    }
    
    private func loadFamilyMembers() async throws {
        let url = URL(string: "\(endpoint)face/v1.0/persongroups/\(personGroupId)/persons")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(subscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return
        }
        
        let persons = try JSONDecoder().decode([Person].self, from: data)
        
        await MainActor.run {
            self.familyMembers = persons
        }
    }
    
    private func getPersonName(personId: String) async throws -> String? {
        let url = URL(string: "\(endpoint)face/v1.0/persongroups/\(personGroupId)/persons/\(personId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(subscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        let person = try JSONDecoder().decode(Person.self, from: data)
        return person.name
    }
}
