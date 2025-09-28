//
//  SplashScreenView.swift
//  lovedones
//
//  Created by Krishna Bhatnagar on 9/28/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                // Background Gradient - Match Dashboard
                LinearGradient(
                    gradient: Gradient(colors: [
                        LovedOnesDesignSystem.warmGray,
                        LovedOnesDesignSystem.pureWhite
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Simple Logo Only
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(
                        color: LovedOnesDesignSystem.primaryRed.opacity(0.3),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                
                // Navigate to main app after 1.75 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

// MARK: - PREVIEW
struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
