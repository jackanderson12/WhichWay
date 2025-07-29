//
//  SearchBarView.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/16/25.
//

import SwiftUI

// MARK: - Search Bar View

/// Search bar for filtering subway stations by name
struct SearchBarView: View {
    
    // MARK: - Properties
    
    @Binding var searchText: String
    @FocusState private var isSearchFocused: Bool
    
    // MARK: - View Body
    var body: some View {
        VStack {
            
            // MARK: - Search Bar Container
            
            HStack(spacing: 12) {
                
                // MARK: - Search Icon
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                
                // MARK: - Search Text Field
                
                TextField("Search subway stations...", text: $searchText)
                    .font(.body)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isSearchFocused)
                    .accessibilityLabel("Station search field")
                    .accessibilityHint("Enter station name to filter results")
                    .onSubmit {
                        isSearchFocused = false
                    }
                
                // MARK: - Clear Button
                
                if !searchText.isEmpty {
                    Button(action: clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Clear search")
                    .accessibilityHint("Removes current search text")
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(searchBarBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Background Styling
    
    /// Search bar background with blur effect
    private var searchBarBackground: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.8)
            
            Rectangle()
                .fill(.regularMaterial)
        }
    }
    
    // MARK: - Action Methods
    
    /// Clears search text and dismisses keyboard
    private func clearSearch() {
        searchText = ""
        isSearchFocused = false
    }
}

// MARK: - Station Filtering Extension
extension SearchBarView {
    
    /// Filters stations by search text (case-insensitive)
    static func filteredStations(_ stations: [SubwayStation], searchText: String) -> [SubwayStation] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedSearchText.isEmpty else {
            return stations
        }
        return stations.filter { station in
            station.name.localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }
}

// MARK: - Preview
#Preview("Empty Search") {
    ZStack {
        // Mock map background
        Rectangle()
            .fill(Color.green.opacity(0.3))
            .ignoresSafeArea()
        
        SearchBarView(searchText: .constant(""))
    }
}

#Preview("Active Search") {
    ZStack {
        // Mock map background  
        Rectangle()
            .fill(Color.green.opacity(0.3))
            .ignoresSafeArea()
        
        SearchBarView(searchText: .constant("Times Square"))
    }
}
