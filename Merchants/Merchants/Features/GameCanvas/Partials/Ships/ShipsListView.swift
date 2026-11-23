////
//  ShipsListView.swift
//  Merchants
//
//  Created by AD on 23/11/2026.
//


import SwiftUI
import MerchantsGame

// Show all the ships of a given player
struct ShipsListView: View {
    let ships:[Ship]
    var body: some View {
        Text("Hello world")
    }
}

#Preview {
    let ships = [
        Ship.init(kind: .standard, cargo: [.init(good: .indigo)]),
        Ship.init(kind: .standard, cargo: [.init(good: .spices)]),
    ]
    ShipsListView(ships: ships)
}
