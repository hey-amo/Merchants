//
//  CratesInSupply.swift
//  Merchants
//

import SwiftUI
import MerchantsGame

// Display all cubes in supply in a grid
// the game has a fixed amount of availability, even if its 0. Can never be < 0; default: 0

// Crates in supply and SingleCrateView may need a helper function to map the crate enum to an image resource

struct CratesInSupplyView: View {
    var body: some View {
        // Crate image
        Text("1") // how many exist in stock
    }
}

#Preview {
    CratesInSupplyView()
}
