//
//  LoadingView.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/9/25.
//

import SwiftUI

// MARK: - Loading View

/**
 * LoadingView - Displays startup loading screen with animated indicators
 * 
 * This view provides visual feedback during the app's startup data loading process.
 * It includes animated loading indicators, status messages, and error handling.
 * 
 * ## Features:
 * - Animated subway-themed loading indicators
 * - Progress status messages
 * - Error display with retry functionality
 * - Smooth transitions between states
 * 
 * ## Design:
 * - Full-screen loading experience
 * - NYC subway branding and colors
 * - Accessible loading indicators
 * - Professional loading animations
 */
struct LoadingView: View {
    
    // MARK: - Properties
    
    /// Current app state to display
    let state: AppState
    
    /// Callback for retry action
    let onRetry: () async -> Void
    
    // MARK: - Animation State
    
    @State private var animationOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.blue.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                
                // MARK: - App Logo/Title
                
                VStack(spacing: 12) {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .scaleEffect(pulseScale)
                        .rotationEffect(.degrees(rotationAngle))
                        .animation(
                            .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                        .animation(
                            .linear(duration: 8.0).repeatForever(autoreverses: false),
                            value: rotationAngle
                        )
                    
                    Text("WhichWay")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("NYC Subway Guide")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // MARK: - Loading Content
                
                VStack(spacing: 24) {
                    
                    switch state {
                    case .loading(let message):
                        LoadingContentView(message: message)
                        
                    case .loaded:
                        LoadedContentView()
                        
                    case .error(let message):
                        ErrorContentView(message: message, onRetry: onRetry)
                    }
                }
                
                Spacer()
            }
            .onAppear {
                startAnimations()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /**
     * Starts the loading animations
     */
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
        
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        LoadingView(state: .loading("Processing stations...")) {
            // Retry action
        }
    }
}