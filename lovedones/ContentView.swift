//
//  ContentView.swift
//  lovedones
//
//  Created by krishna bhatnagar on 9/27/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var faceManager = FaceRecognitionManager()
    @StateObject private var authManager = UserAuthManager()
    @State private var showingFaceRecognition = false
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showSplash = false
                            }
                        }
                    }
            } else if authManager.isAuthenticated {
                if authManager.isCaregiver {
                    // Caregiver Dashboard
                    CaregiverDashboard()
                        .environmentObject(authManager)
                } else {
                    // Patient Dashboard
                    TabView {
                        // Main Dashboard
                        HackathonWinningDashboard()
                            .tabItem {
                                Image(systemName: "house.fill")
                                Text("Home")
                            }
                        
                        // Face Recognition
                        FaceRecognitionCameraView()
                            .tabItem {
                                Image(systemName: "camera.fill")
                                Text("Face ID")
                            }
                        
                        
                        // Daily Checkpoint
                        CognitiveAssessmentView()
                            .tabItem {
                                Image(systemName: "brain.head.profile")
                                Text("Checkpoint")
                            }
                        
                        // Memory Lane
                        MemoryLaneView()
                            .tabItem {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Memory Lane")
                            }
                        
                        // Health Dashboard
                        HealthDashboardView()
                            .environmentObject(authManager)
                            .tabItem {
                                Image(systemName: "heart.fill")
                                Text("Health")
                            }
                    }
                    .accentColor(Color(red: 0.8, green: 0.4, blue: 0.8))
                    .task {
                        await faceManager.loadRegisteredFaces()
                    }
                }
            } else {
                AuthenticationView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            print("🔍 ContentView appeared - isAuthenticated: \(authManager.isAuthenticated)")
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            print("🔍 ContentView - Authentication state changed: \(isAuthenticated)")
        }
    }
}

#Preview {
    ContentView()
}
