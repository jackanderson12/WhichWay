//
//  AppStateManager.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/9/25.
//

import Foundation
import SwiftUI
import SwiftData
import Observation

// MARK: - App State

enum AppState: Equatable {
    case loading(String)
    case loaded
    case error(String)

    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.loading(let l), .loading(let r)): return l == r
        case (.loaded, .loaded): return true
        case (.error(let l), .error(let r)): return l == r
        default: return false
        }
    }
}

// MARK: - App State Manager

@MainActor
@Observable
class AppStateManager {
    var state: AppState = .loading("Initializing...")

    private let mtaService: MTAServiceProtocol
    private var modelContext: ModelContext?

    init(mtaService: MTAServiceProtocol = MTAService()) {
        self.mtaService = mtaService
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func startDataLoading() async {
        do {
            state = .loading("Downloading subway data...")
            try await mtaService.fetchBaseData()

            state = .loading("Processing stations and routes...")
            try await mtaService.decodeBaseData(context: modelContext)

            state = .loading("Finalizing...")
            try await Task.sleep(for: .milliseconds(500))

            state = .loaded
        } catch {
            state = .error("Failed to load subway data: \(error.localizedDescription)")
        }
    }

    func retryDataLoading() async {
        state = .loading("Retrying...")
        await startDataLoading()
    }
}
