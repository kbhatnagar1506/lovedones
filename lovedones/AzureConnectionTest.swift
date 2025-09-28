//
//  AzureConnectionTest.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/27/25.
//

import SwiftUI
import PhotosUI

// MARK: - Azure Connection Test View
struct AzureConnectionTestView: View {
    @StateObject private var faceService = AzureFaceService.shared
    @State private var testImage: UIImage?
    @State private var showingImagePicker = false
    @State private var testResults: [FaceDetectionResult] = []
    @State private var isTesting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Section
                VStack(spacing: 12) {
                    HStack {
                        Circle()
                            .fill(faceService.isInitialized ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text(faceService.isInitialized ? "Azure Connected" : "Connecting to Azure...")
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                    
                    if let error = faceService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Test Image Section
                VStack(spacing: 16) {
                    Text("Test Face Detection")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    
                    if let testImage = testImage {
                        Image(uiImage: testImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("No image selected")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                    
                    Button("Select Test Image") {
                        showingImagePicker = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                // Test Results Section
                if !testResults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Detection Results")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        ForEach(Array(testResults.enumerated()), id: \.offset) { index, result in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Face \(index + 1)")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    if let personName = result.personName {
                                        Text(personName)
                                            .font(.subheadline)
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(8)
                                    } else {
                                        Text("Unknown")
                                            .font(.subheadline)
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.red.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                }
                                
                                if let attributes = result.faceAttributes {
                                    VStack(alignment: .leading, spacing: 4) {
                                        if let age = attributes.age {
                                            Text("Age: \(Int(age))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        if let gender = attributes.gender {
                                            Text("Gender: \(gender)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        if let emotion = attributes.emotion {
                                            let dominantEmotion = getDominantEmotion(emotion)
                                            Text("Emotion: \(dominantEmotion)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                    }
                }
                
                // Test Button
                if testImage != nil {
                    Button(action: testFaceDetection) {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            
                            Text(isTesting ? "Testing..." : "Test Face Detection")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(isTesting ? Color.gray : Color.red)
                        .cornerRadius(12)
                    }
                    .disabled(isTesting)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Azure Test")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker) {
                PhotoPicker(selectedImage: $testImage)
            }
        }
    }
    
    private func testFaceDetection() {
        guard let image = testImage else { return }
        
        isTesting = true
        testResults = []
        
        Task {
            do {
                let results = try await faceService.detectFaces(in: image)
                
                await MainActor.run {
                    self.testResults = results
                    self.isTesting = false
                }
            } catch {
                await MainActor.run {
                    self.testResults = []
                    self.isTesting = false
                }
            }
        }
    }
    
    private func getDominantEmotion(_ emotion: Emotion) -> String {
        let anger = emotion.anger ?? 0
        let contempt = emotion.contempt ?? 0
        let disgust = emotion.disgust ?? 0
        let fear = emotion.fear ?? 0
        let happiness = emotion.happiness ?? 0
        let neutral = emotion.neutral ?? 0
        let sadness = emotion.sadness ?? 0
        let surprise = emotion.surprise ?? 0
        
        let emotions: [(String, Double)] = [
            ("anger", anger),
            ("contempt", contempt),
            ("disgust", disgust),
            ("fear", fear),
            ("happiness", happiness),
            ("neutral", neutral),
            ("sadness", sadness),
            ("surprise", surprise)
        ]
        
        let dominant = emotions.max { $0.1 < $1.1 }
        return dominant?.0.capitalized ?? "Unknown"
    }
}

