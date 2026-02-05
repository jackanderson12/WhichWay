//
//  ContentView.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/15/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.modelContext) var modelContext
    @State private var appStateManager = AppStateManager()

    var body: some View {
        ZStack {
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
        .ignoresSafeArea(.all)
        .animation(.easeInOut(duration: 0.5), value: appStateManager.state)
        .onAppear {
            appStateManager.setModelContext(modelContext)
            Task {
                await appStateManager.startDataLoading()
            }
        }
    }
}

#Preview {
    ContentView()
}
