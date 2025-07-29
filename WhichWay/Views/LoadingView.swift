//
//  LoadingView.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/9/25.
//

import SwiftUI

// MARK: - Loading View

/// Startup loading screen with animated indicators and error handling
struct LoadingView: View {
    
    // MARK: - Properties
    
    let state: AppState
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
                        loadingContent(message: message)
                        
                    case .loaded:
                        loadedContent()
                        
                    case .error(let message):
                        errorContent(message: message)
                    }
                }
                
                Spacer()
            }
            .onAppear {
                startAnimations()
            }
        }
    }
    
    // MARK: - Loading Content
    
    private func loadingContent(message: String) -> some View {
        VStack(spacing: 20) {
            
            // Animated progress indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
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
                .font(.body)
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
    
    private func loadedContent() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.green)
                .scaleEffect(1.1)
            
            Text("Ready to explore!")
                .font(.body)
                .foregroundColor(.primary)
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Error Content
    
    private func errorContent(message: String) -> some View {
        VStack(spacing: 20) {
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text("Loading Failed")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.caption)
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
                .font(.body)
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
    
    /// Starts the loading animations
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