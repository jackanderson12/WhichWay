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
            
            VStack(spacing: 40) {
                
                // MARK: - App Logo/Title
                
                VStack(spacing: 16) {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 64))
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
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("NYC Subway Guide")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // MARK: - Loading Content
                
                VStack(spacing: 24) {
                    
                    switch state {
                    case .loading(let message):
                        loadingContent(message: message)
                        
                    case .loaded:
                        loadedContent()
                        
                    case .error(let message):
                        errorContent(message: message)
                    }
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                startAnimations()
            }
        }
    }
    
    // MARK: - Loading Content
    
    @ViewBuilder
    private func loadingContent(message: String) -> some View {
        VStack(spacing: 20) {
            
            // Animated progress indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                        .scaleEffect(index == Int(animationOffset) ? 1.5 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .onAppear {
                withAnimation {
                    animationOffset = 2
                }
            }
            
            // Status message
            Text(message)
                .font(.title3)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .transition(.opacity)
            
            // Subway line animation
            HStack(spacing: 4) {
                ForEach(["1", "2", "3", "4", "5", "6"], id: \.self) { line in
                    SubwayLineIndicator(line: line)
                        .scaleEffect(pulseScale)
                }
            }
        }
    }
    
    // MARK: - Loaded Content
    
    @ViewBuilder
    private func loadedContent() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
                .scaleEffect(1.2)
            
            Text("Ready to explore!")
                .font(.title3)
                .foregroundColor(.primary)
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Error Content
    
    @ViewBuilder
    private func errorContent(message: String) -> some View {
        VStack(spacing: 20) {
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Loading Failed")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await onRetry()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .transition(.scale.combined(with: .opacity))
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

// MARK: - Subway Line Indicator

/**
 * SubwayLineIndicator - Small animated indicator for subway lines
 * 
 * Displays a subway line number with authentic NYC subway styling.
 */
struct SubwayLineIndicator: View {
    let line: String
    
    var body: some View {
        Text(line)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(lineColor(for: line))
            .clipShape(Circle())
    }
    
    private func lineColor(for line: String) -> Color {
        switch line {
        case "1", "2", "3":
            return Color(hex: "EE352E") // Red
        case "4", "5", "6":
            return Color(hex: "00933C") // Green
        default:
            return Color.blue
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