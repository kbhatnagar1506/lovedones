import Foundation
import SwiftUI
import AVFoundation
import UIKit
import CoreImage

// MARK: - Data Models
struct FaceRegistrationRequest: Codable {
    let imageData: String
    let personName: String
    let relationship: String
    let additionalInfo: String?
}

struct FaceRecognitionRequest: Codable {
    let imageData: String
    let tolerance: Double?
}

struct FaceLandmarksRequest: Codable {
    let imageData: String
}

struct FaceRecognitionResult: Codable, Identifiable {
    let id = UUID()
    let faceId: String?
    let personName: String
    let relationship: String
    let additionalInfo: String?
    let confidence: Double
    let landmarks: [String: [[Double]]]
    let faceLocation: [Int]
    
    enum CodingKeys: String, CodingKey {
        case faceId = "face_id"
        case personName = "person_name"
        case relationship
        case additionalInfo = "additional_info"
        case confidence
        case landmarks
        case faceLocation = "face_location"
    }
}

struct FaceRecognitionResponse: Codable {
    let success: Bool
    let error: String?
    let facesDetected: Int?
    let results: [FaceRecognitionResult]?
    
    enum CodingKeys: String, CodingKey {
        case success
        case error
        case facesDetected = "faces_detected"
        case results
    }
}

struct FaceLandmarksResponse: Codable {
    let success: Bool
    let error: String?
    let facesDetected: Int?
    let landmarks: [FaceLandmarkData]?
    
    enum CodingKeys: String, CodingKey {
        case success
        case error
        case facesDetected = "faces_detected"
        case landmarks
    }
}

struct FaceLandmarkData: Codable, Identifiable {
    let id = UUID()
    let faceIndex: Int
    let faceLocation: [Int]
    let landmarks: [String: [[Double]]]
    
    enum CodingKeys: String, CodingKey {
        case faceIndex = "face_index"
        case faceLocation = "face_location"
        case landmarks
    }
}

struct RegisteredFace: Codable, Identifiable {
    let id = UUID()
    let faceId: String
    let personName: String
    let relationship: String
    let additionalInfo: String
    let registeredAt: String
    
    enum CodingKeys: String, CodingKey {
        case faceId = "face_id"
        case personName = "person_name"
        case relationship
        case additionalInfo = "additional_info"
        case registeredAt = "registered_at"
    }
}

struct RegisteredFacesResponse: Codable {
    let success: Bool
    let error: String?
    let faces: [RegisteredFace]?
    let totalFaces: Int?
    
    enum CodingKeys: String, CodingKey {
        case success
        case error
        case faces
        case totalFaces = "total_faces"
    }
}

struct FaceRegistrationResponse: Codable {
    let success: Bool
    let error: String?
    let faceId: String?
    let personName: String?
    let relationship: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case error
        case faceId = "face_id"
        case personName = "person_name"
        case relationship
        case message
    }
}

struct FaceDeleteResponse: Codable {
    let success: Bool
    let error: String?
    let message: String?
}

struct FaceVectorTestResponse: Codable {
    let success: Bool
    let error: String?
    let faceDetected: Bool
    let faceLocation: [Int]
    let vectorSize: Int
    let vectorSample: [Double]
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case error
        case faceDetected = "face_detected"
        case faceLocation = "face_location"
        case vectorSize = "vector_size"
        case vectorSample = "vector_sample"
        case message
    }
}

// MARK: - Face Recognition Manager
@MainActor
class FaceRecognitionManager: ObservableObject {
    @Published var isRecognizing = false
    @Published var recognitionResults: [FaceRecognitionResult] = []
    @Published var faceLandmarks: [FaceLandmarkData] = []
    @Published var registeredFaces: [RegisteredFace] = []
    @Published var errorMessage: String?
    @Published var isRegistering = false
    @Published var showGreenFlash = false
    @Published var lastRecognizedFace: FaceRecognitionResult?
    @Published var recognitionConfidence: Double = 0.0
    @Published var processingTime: TimeInterval = 0.0
    @Published var retryCount = 0
    @Published var isRetrying = false
    @Published var detectionQuality: String = "Unknown"
    
    private let baseURL = "https://lovedones-face-recognition-810d8ea9f3d0.herokuapp.com"
    
    // MARK: - Face Recognition
    func recognizeFaces(from image: UIImage, tolerance: Double = 0.6) async {
        let startTime = Date()
        
        // Preprocess image for better recognition
        guard let processedImage = preprocessImage(image) else {
            errorMessage = "Failed to preprocess image"
            return
        }
        
        // Check image quality
        let quality = assessImageQuality(processedImage)
        detectionQuality = quality
        
        guard let imageData = processedImage.jpegData(compressionQuality: 0.9) else {
            errorMessage = "Failed to convert image to data"
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        isRecognizing = true
        errorMessage = nil
        retryCount = 0
        
        // Retry logic for better reliability
        await performRecognitionWithRetry(base64String: base64String, tolerance: tolerance)
        
        processingTime = Date().timeIntervalSince(startTime)
        isRecognizing = false
    }
    
    private func performRecognitionWithRetry(base64String: String, tolerance: Double, maxRetries: Int = 3) async {
        for attempt in 1...maxRetries {
            do {
                let request = FaceRecognitionRequest(imageData: base64String, tolerance: tolerance)
                let response: FaceRecognitionResponse = try await makeAPICall(
                    endpoint: "/face/recognize",
                    method: "POST",
                    body: request
                )
                
                if response.success {
                    recognitionResults = response.results ?? []
                    
                    // Calculate average confidence
                    if !recognitionResults.isEmpty {
                        let avgConfidence = recognitionResults.map { $0.confidence }.reduce(0, +) / Double(recognitionResults.count)
                        recognitionConfidence = avgConfidence
                        
                        // Show green flash for successful recognition
                        showGreenFlash = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.showGreenFlash = false
                        }
                        
                        // Store the last recognized face
                        lastRecognizedFace = recognitionResults.first
                    }
                    
                    await getFaceLandmarks(from: UIImage(data: Data(base64Encoded: base64String)!)!)
                    retryCount = 0
                    return // Success, exit retry loop
                } else {
                    errorMessage = response.error ?? "Recognition failed"
                }
            } catch {
                errorMessage = "Failed to recognize faces: \(error.localizedDescription)"
            }
            
            // If not the last attempt, wait before retrying
            if attempt < maxRetries {
                retryCount = attempt
                isRetrying = true
                try? await Task.sleep(nanoseconds: UInt64(attempt * 1_000_000_000)) // Exponential backoff
            }
        }
        
        isRetrying = false
    }
    
    // MARK: - Image Preprocessing
    private func preprocessImage(_ image: UIImage) -> UIImage? {
        // Resize image to optimal size for face recognition
        let targetSize = CGSize(width: 800, height: 600)
        let resizedImage = image.resized(to: targetSize)
        
        // Enhance image quality
        guard let enhancedImage = enhanceImageQuality(resizedImage) else {
            return resizedImage
        }
        
        return enhancedImage
    }
    
    private func enhanceImageQuality(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        
        // Apply contrast and brightness adjustments
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.1, forKey: kCIInputContrastKey) // Slight contrast boost
        filter?.setValue(0.05, forKey: kCIInputBrightnessKey) // Slight brightness boost
        filter?.setValue(1.0, forKey: kCIInputSaturationKey)
        
        guard let outputImage = filter?.outputImage,
              let enhancedCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: enhancedCGImage)
    }
    
    private func assessImageQuality(_ image: UIImage) -> String {
        guard let cgImage = image.cgImage else { return "Poor" }
        
        // Simple quality assessment based on image dimensions and properties
        let width = cgImage.width
        let height = cgImage.height
        
        if width >= 600 && height >= 400 {
            return "Excellent"
        } else if width >= 400 && height >= 300 {
            return "Good"
        } else if width >= 300 && height >= 200 {
            return "Fair"
        } else {
            return "Poor"
        }
    }
    
    func getFaceLandmarks(from image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        do {
            let request = FaceLandmarksRequest(imageData: base64String)
            let response: FaceLandmarksResponse = try await makeAPICall(
                endpoint: "/face/landmarks",
                method: "POST",
                body: request
            )
            
            if response.success {
                faceLandmarks = response.landmarks ?? []
            }
        } catch {
            print("Failed to get face landmarks: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Face Registration
    func registerFace(image: UIImage, personName: String, relationship: String, additionalInfo: String = "") async -> Bool {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to convert image to data"
            return false
        }
        
        let base64String = imageData.base64EncodedString()
        
        isRegistering = true
        errorMessage = nil
        
        do {
            let request = FaceRegistrationRequest(
                imageData: base64String,
                personName: personName,
                relationship: relationship,
                additionalInfo: additionalInfo.isEmpty ? nil : additionalInfo
            )
            
            let response: FaceRegistrationResponse = try await makeAPICall(
                endpoint: "/face/register",
                method: "POST",
                body: request
            )
            
            if response.success {
                await loadRegisteredFaces()
                return true
            } else {
                errorMessage = response.error ?? "Unknown error"
                return false
            }
        } catch {
            errorMessage = "Failed to register face: \(error.localizedDescription)"
            return false
        }
        
        isRegistering = false
    }
    
    // MARK: - Load Registered Faces
    func loadRegisteredFaces() async {
        do {
            let response: RegisteredFacesResponse = try await makeAPICall(
                endpoint: "/face/registered",
                method: "GET"
            )
            
            if response.success {
                registeredFaces = response.faces ?? []
            } else {
                errorMessage = response.error ?? "Failed to load registered faces"
            }
        } catch {
            errorMessage = "Failed to load registered faces: \(error.localizedDescription)"
        }
    }
    
    func processFrameForRecognition(_ image: UIImage) async {
        // Throttle processing to avoid overwhelming the server
        guard !isRecognizing else { return }
        
        isRecognizing = true
        
        // Convert image to base64 with higher quality for better face detection
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            isRecognizing = false
            return
        }
        let base64String = imageData.base64EncodedString()
        
        do {
            // Get face landmarks for visualization
            let landmarksRequest = FaceLandmarksRequest(imageData: base64String)
            let landmarksResponse: FaceLandmarksResponse = try await makeAPICall(
                endpoint: "/face/landmarks",
                method: "POST",
                body: landmarksRequest
            )
            
            if landmarksResponse.success, let landmarks = landmarksResponse.landmarks {
                faceLandmarks = landmarks
            }
            
            // Try to recognize faces
            let recognitionRequest = FaceRecognitionRequest(imageData: base64String, tolerance: 0.6)
            let recognitionResponse: FaceRecognitionResponse = try await makeAPICall(
                endpoint: "/face/recognize",
                method: "POST",
                body: recognitionRequest
            )
            
            if recognitionResponse.success, let results = recognitionResponse.results {
                recognitionResults = results
                
                // Check if any face was successfully recognized (confidence > 0.7)
                let recognizedFaces = results.filter { $0.confidence > 0.7 }
                if !recognizedFaces.isEmpty {
                    // Trigger green flash for successful recognition
                    lastRecognizedFace = recognizedFaces.first
                    triggerGreenFlash()
                }
            } else {
                // If no faces recognized, clear results
                recognitionResults = []
            }
            
        } catch {
            // Silently handle errors for real-time processing
            print("Face recognition error: \(error.localizedDescription)")
        }
        
        isRecognizing = false
    }
    
    // MARK: - Green Flash Feedback
    func triggerGreenFlash() {
        showGreenFlash = true
        
        // Auto-hide the flash after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showGreenFlash = false
        }
    }
    
    // MARK: - Face Vector Testing
    func testFaceVectorization(image: UIImage) async -> Bool {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to data")
            return false
        }
        
        let base64String = imageData.base64EncodedString()
        
        do {
            let request = FaceLandmarksRequest(imageData: base64String)
            let response: FaceVectorTestResponse = try await makeAPICall(
                endpoint: "/face/verify-vector",
                method: "POST",
                body: request
            )
            
            if response.success {
                print("✅ Face vectorization test successful:")
                print("   - Face detected: \(response.faceDetected)")
                print("   - Vector size: \(response.vectorSize)")
                print("   - Vector sample: \(response.vectorSample)")
                print("   - Message: \(response.message)")
                return true
            } else {
                print("❌ Face vectorization test failed: \(response.error ?? "Unknown error")")
                return false
            }
        } catch {
            print("❌ Face vectorization test error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Delete Face
    func deleteFace(faceId: String) async -> Bool {
        do {
            let response: FaceDeleteResponse = try await makeAPICall(
                endpoint: "/face/delete/\(faceId)",
                method: "DELETE"
            )
            
            if response.success {
                await loadRegisteredFaces()
                return true
            } else {
                errorMessage = response.error ?? "Unknown error"
                return false
            }
        } catch {
            errorMessage = "Failed to delete face: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func makeAPICall<T: Codable, R: Codable>(endpoint: String, method: String, body: T? = nil) async throws -> R {
        guard let url = URL(string: baseURL + endpoint) else {
            throw FaceRecognitionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        print("🔍 Making API call to: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FaceRecognitionError.invalidResponse
        }
        
        print("🔍 API Response Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response data"
            print("❌ API Error Response: \(responseString)")
            throw FaceRecognitionError.apiError(httpResponse.statusCode, "Server returned error status")
        }
        
        // Debug: Print response data
        let responseString = String(data: data, encoding: .utf8) ?? "No response data"
        print("🔍 API Response Data: \(responseString)")
        
        do {
            return try JSONDecoder().decode(R.self, from: data)
        } catch {
            print("❌ JSON Decoding Error: \(error)")
            print("❌ Expected type: \(R.self)")
            print("❌ Response data: \(responseString)")
            throw error
        }
    }
    
    private func makeAPICall<R: Codable>(endpoint: String, method: String) async throws -> R {
        guard let url = URL(string: baseURL + endpoint) else {
            throw FaceRecognitionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        print("🔍 Making API call to: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FaceRecognitionError.invalidResponse
        }
        
        print("🔍 API Response Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response data"
            print("❌ API Error Response: \(responseString)")
            throw FaceRecognitionError.apiError(httpResponse.statusCode, "Server returned error status")
        }
        
        // Debug: Print response data
        let responseString = String(data: data, encoding: .utf8) ?? "No response data"
        print("🔍 API Response Data: \(responseString)")
        
        do {
            return try JSONDecoder().decode(R.self, from: data)
        } catch {
            print("❌ JSON Decoding Error: \(error)")
            print("❌ Expected type: \(R.self)")
            print("❌ Response data: \(responseString)")
            throw error
        }
    }
}

// MARK: - Error Types
enum FaceRecognitionError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .apiError(let code, let message):
            return "API Error \(code): \(message)"
        }
    }
}

// MARK: - Face Landmark Visualization Helper
struct FaceLandmarkPoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let landmarkType: String
}

extension FaceRecognitionManager {
    func getLandmarkPoints(for faceIndex: Int) -> [FaceLandmarkPoint] {
        guard faceIndex < faceLandmarks.count else { return [] }
        
        let landmarkData = faceLandmarks[faceIndex]
        var points: [FaceLandmarkPoint] = []
        
        for (landmarkType, coordinates) in landmarkData.landmarks {
            for coordinate in coordinates {
                if coordinate.count >= 2 {
                    points.append(FaceLandmarkPoint(
                        x: coordinate[0],
                        y: coordinate[1],
                        landmarkType: landmarkType
                    ))
                }
            }
        }
        
        return points
    }
    
    func getFaceBoundingBox(for faceIndex: Int) -> CGRect? {
        guard faceIndex < faceLandmarks.count else { return nil }
        
        let faceLocation = faceLandmarks[faceIndex].faceLocation
        // face_location format: [top, right, bottom, left]
        if faceLocation.count >= 4 {
            return CGRect(
                x: Double(faceLocation[3]), // left
                y: Double(faceLocation[0]), // top
                width: Double(faceLocation[1] - faceLocation[3]), // right - left
                height: Double(faceLocation[2] - faceLocation[0]) // bottom - top
            )
        }
        
        return nil
    }
}

// MARK: - UIImage Extension for Image Processing
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
