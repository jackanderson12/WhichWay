//
//  RouteBadge.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/29/25.
//
import SwiftUI

// MARK: - Route Badge

/// Badge displaying subway route with MTA colors
struct RouteBadge: View {
    
    let line: StationLine
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color(hex: line.displayColor))
                    .frame(width: 40, height: 40)
                
                Text(line.routeName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: line.displayTextColor))
            }
            
            Text(line.routeName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
