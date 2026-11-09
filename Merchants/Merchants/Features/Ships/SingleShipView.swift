//
//  SingleShipView.swift
//  Merchants
//

import SwiftUI

// Display a single ship asset resource
// with: no cargo (default state)
// with: 1 cube
// with: 2 cubes (large ship supported)
// if more, defaults to 2 (or maybe it can't show it)

struct SingleShipView: View {
    let crates: Int = 0
    var body: some View {
        Image("ship-nobg")
        // If > 0 crates
        // Add Single crate view per # of crates
        // and type of crate to show
    }
}

#Preview {
    SingleShipView()
}
