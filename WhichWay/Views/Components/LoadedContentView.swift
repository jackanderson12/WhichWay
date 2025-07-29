//
//  LoadedContentView.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/29/25.
//

import SwiftUI

// Success/loaded state content
struct LoadedContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.green)
                .scaleEffect(1.1)
            
            Text("Ready to explore!")
                .font(.body)
                .foregroundColor(.primary)
        }
        .transition(.scale.combined(with: .opacity))
    }
}