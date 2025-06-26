//
//  ContentView.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/15/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var context
    
    var body: some View {
        MapView()
    }
}

#Preview {
    ContentView()
}
