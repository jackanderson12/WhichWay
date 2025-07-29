//
//  LineDirectionSection.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/29/25.
//
import SwiftUI

// MARK: - Line Direction Section

/**
 * LineDirectionSection - Section displaying lines for a specific direction
 * 
 * Shows a group of subway lines organized by direction with
 * route badges and line information.
 */
struct LineDirectionSection: View {
    
    let direction: LineDirection
    let lines: [StationLine]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Direction Header
            HStack {
                Image(systemName: direction.systemImage)
                    .foregroundColor(direction == .uptown ? .blue : .green)
                    .font(.title3)
                
                Text(direction.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(lines.count) line\(lines.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Lines Grid
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80, maximum: 120), spacing: 12)
            ], spacing: 12) {
                ForEach(lines) { line in
                    RouteBadge(line: line)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
