////
//  CardsRemainingLabelView.swift
//  Merchants
//
//  Created by AD on 23/11/2026.
//

import SwiftUI
import Foundation
import MerchantsGame

// Displays the current phase of the game
struct CardsRemainingLabelView: View {
    let cardsLeft: UInt32

    var body: some View {
        HStack {
            Text("Cards Left:")
            Text("\(cardsLeft)")
        }
    }
}

#Preview {
    let cardsLeft: UInt32 = 30
    CardsRemainingLabelView(cardsLeft: cardsLeft)
}
