//
//  LoadingContentView.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/29/25.
//

import SwiftUI

// Loading content with animated indicators
struct LoadingContentView: View {
    let message: String
    @State private var animationOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
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
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}