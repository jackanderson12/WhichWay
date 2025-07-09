//
//  ContentView.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/15/25.
//

import SwiftUI
import SwiftData

// MARK: - Content View

/**
 * ContentView - Main content view that manages app state transitions
 * 
 * This view coordinates the transition between loading and main app content
 * based on the current application state. It provides a smooth user experience
 * during app startup and data loading.
 * 
 * ## Features:
 * - State-driven view switching
 * - Smooth transitions between loading and map views
 * - SwiftData context integration
 * - Automatic startup data loading
 * 
 * ## States:
 * - Loading: Shows LoadingView with progress indicators
 * - Loaded: Displays the main MapView
 * - Error: Shows error message with retry option
 */
struct ContentView: View {
    
    // MARK: - Environment
    
    /// SwiftData model context for persistence
    @Environment(\.modelContext) var modelContext
    
    /// App state manager for startup coordination
    @StateObject private var appStateManager = AppStateManager()
    
    // MARK: - View Body
    
    var body: some View {
        Group {
            switch appStateManager.state {
            case .loading, .error:
                LoadingView(
                    state: appStateManager.state,
                    onRetry: {
                        await appStateManager.retryDataLoading()
                    }
                )
                .transition(.opacity)
                
            case .loaded:
                MapView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appStateManager.state)
        .onAppear {
            setupAppState()
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * Sets up the app state manager and starts data loading
     */
    private func setupAppState() {
        // Provide SwiftData context to the state manager
        appStateManager.setModelContext(modelContext)
        
        // Start the data loading process
        Task {
            await appStateManager.startDataLoading()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
