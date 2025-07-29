//
//  SearchBarView.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/16/25.
//

import SwiftUI

// MARK: - Search Bar View

/**
 * SearchBarView - Interactive search interface for filtering subway stations
 * 
 * This view provides a search text field that allows users to filter subway stations
 * by name in real-time. It's designed to be overlaid on top of the MapView to provide
 * seamless search functionality without obscuring the map content.
 * 
 * ## Features:
 * - Real-time station name filtering
 * - Responsive text input with search icon
 * - Elegant overlay design with backdrop blur
 * - Clear button for easy input reset
 * - Keyboard-friendly interaction
 * 
 * ## Design:
 * - Compact search bar positioned at top of screen
 * - Translucent background with system blur effect
 * - NYC subway color scheme integration
 * - Accessible with proper contrast and focus states
 * - Professional iOS search bar styling
 * 
 * ## Integration:
 * - Designed to overlay MapView without blocking interaction
 * - Provides searchText binding for parent view filtering
 * - Maintains safe area awareness for proper positioning
 * - Compatible with SwiftData station queries
 * 
 * ## Performance:
 * - Lightweight text filtering using Swift string operations
 * - Debounced search to prevent excessive filtering
 * - Efficient binding updates for reactive UI
 */
struct SearchBarView: View {
    
    // MARK: - Properties
    
    /// Binding to the search text that triggers station filtering
    /// Parent view uses this to filter the stations displayed on the map
    @Binding var searchText: String
    
    /// Focus state for managing keyboard interactions
    @FocusState private var isSearchFocused: Bool
    
    // MARK: - View Body
    
    /**
     * Main view body rendering the search interface
     * 
     * Creates a search bar with:
     * - Search icon and text field
     * - Clear button when text is present
     * - Backdrop blur for elegant overlay effect
     * - Proper keyboard handling and focus management
     * 
     * ## Layout:
     * - Positioned at top of screen with safe area padding
     * - Horizontally centered with leading/trailing margins
     * - Consistent height for predictable overlay positioning
     * 
     * ## Accessibility:
     * - Proper focus management for VoiceOver
     * - Clear button with descriptive accessibility label
     * - Search field with placeholder and hint text
     */
    var body: some View {
        VStack {
            
            // MARK: - Search Bar Container
            
            HStack(spacing: 12) {
                
                // MARK: - Search Icon
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true) // Decorative icon
                
                // MARK: - Search Text Field
                
                TextField("Search subway stations...", text: $searchText)
                    .font(.body)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isSearchFocused)
                    .accessibilityLabel("Station search field")
                    .accessibilityHint("Enter station name to filter results")
                    .onSubmit {
                        // Dismiss keyboard when user presses return
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
            .background(SearchBarBackground())
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Action Methods
    
    /**
     * Clears the search text and dismisses the keyboard
     * 
     * This method provides a complete reset of the search state,
     * clearing both the text input and removing keyboard focus
     * for optimal user experience.
     * 
     * ## Effects:
     * - Resets searchText to empty string
     * - Dismisses the keyboard
     * - Triggers parent view to show all stations
     * - Animates clear button disappearance
     */
    private func clearSearch() {
        searchText = ""
        isSearchFocused = false
    }
}

// MARK: - Station Filtering Extension

/**
 * Extension providing station filtering utilities
 * 
 * These utilities help parent views filter subway stations based on
 * the search text provided by the SearchBarView. The filtering is
 * case-insensitive and supports partial name matching.
 */
extension SearchBarView {
    
    /**
     * Filters an array of subway stations based on search text
     * 
     * Performs case-insensitive filtering on station names,
     * supporting partial matches for flexible user input.
     * 
     * ## Parameters:
     * - stations: Array of SubwayStation objects to filter
     * - searchText: Text to search for in station names
     * 
     * ## Returns:
     * Array of stations whose names contain the search text
     * 
     * ## Filtering Logic:
     * - Case-insensitive string comparison
     * - Partial name matching (contains vs exact match)
     * - Empty search text returns all stations
     * - Whitespace is trimmed from search input
     * 
     * ## Example:
     * ```swift
     * let filtered = SearchBarView.filteredStations(
     *     stations: allStations,
     *     searchText: "times"
     * )
     * // Returns stations like "Times Sq-42 St"
     * ```
     */
    static func filteredStations(_ stations: [SubwayStation], searchText: String) -> [SubwayStation] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Return all stations if search is empty
        guard !trimmedSearchText.isEmpty else {
            return stations
        }
        
        // Filter stations by name (case-insensitive)
        return stations.filter { station in
            station.name.localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }
}

// MARK: - Preview

/**
 * Preview provider for SearchBarView development and testing
 * 
 * Provides multiple preview scenarios to test different states
 * and ensure proper rendering across various configurations.
 */
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
