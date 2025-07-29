//
//  SearchBarBackground.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/29/25.
//
import SwiftUI

// MARK: - Background Styling

/**
 * Creates the search bar background with system blur effect
 *
 * Uses a combination of translucent background color and system
 * blur effect to create an elegant overlay that doesn't completely
 * obscure the map content underneath.
 *
 * ## Visual Effect:
 * - Translucent white background for light mode
 * - Automatic dark mode adaptation
 * - System blur for depth and modern iOS aesthetic
 * - Maintains map visibility while ensuring text readability
 */
struct SearchBarBackground: View {
    var body: some View {
        ZStack {
            // Base background color
            Color(.systemBackground)
                .opacity(0.8)
            
            // System blur effect for modern iOS look
            Rectangle()
                .fill(.regularMaterial)
        }
    }
}
