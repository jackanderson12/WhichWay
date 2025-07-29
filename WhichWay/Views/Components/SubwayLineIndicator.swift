//
//  SubwayLineIndicator.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/29/25.
//

import SwiftUI

// MARK: - Subway Line Indicator

/// Small indicator displaying subway line with MTA colors
struct SubwayLineIndicator: View {
    let line: String
    
    var body: some View {
        Text(line)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(lineColor(for: line))
            .clipShape(Circle())
    }
    
    private func lineColor(for line: String) -> Color {
        switch line {
        case "1", "2", "3":
            return Color(hex: "EE352E") // Red
        case "4", "5", "6":
            return Color(hex: "00933C") // Green
        default:
            return Color.blue
        }
    }
}

// MARK: - Preview

#Preview {
    HStack {
        SubwayLineIndicator(line: "1")
        SubwayLineIndicator(line: "4")
        SubwayLineIndicator(line: "N")
    }
}