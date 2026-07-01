//
//  CyclingPathView.swift
//  Commute
//
//  Created by Ryan on 27/6/26.
//

import SwiftUI
import SwiftData

struct CyclingPathView: View {
    var body: some View {
        VStack {
            Text("hello, world!")
            Button {
                Task {
                    await fetchCyclingPathData()
                }
            } label: {
                Text("Fetch Data")
            }
            Button(action: printHello) {
                Text("Say hello")
            }
        }
    }
    
    func printHello() {
        print("hello, world!")
    }
}


#Preview {
    CyclingPathView()
        .modelContainer(for: Item.self, inMemory: true)
}
