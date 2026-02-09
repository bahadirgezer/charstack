//
//  ContentView.swift
//  Charstack
//
//  Created by Bahadır Gezer on 18/01/2026.
//

// DEPRECATED: This file is superseded by App/RootView.swift as of Week 2.
// Kept as a placeholder for quick testing/debugging.
// The app entry point (CharstackApp.swift) uses RootView, not this file.

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
