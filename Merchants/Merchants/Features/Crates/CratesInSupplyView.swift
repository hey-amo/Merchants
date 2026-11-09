//
//  CratesInSupply.swift
//  Merchants
//

import SwiftUI

// Display all cubes in supply
// the game has a fixed amount of availability, even if its 0. Can never be < 0; default: 0

struct CratesInSupplyView: View {
    var body: some View {

        SingleCrateView()
        Text("1") // how many exist in stock
    }
}

#Preview {
    CratesInSupplyView()
}
