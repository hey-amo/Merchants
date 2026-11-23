//
//  CurrentPhaseLabelView.swift
//  Merchants
//
//  Created by Amarjit on 10/11/2026.
//

import SwiftUI
import Foundation
import MerchantsGame

// Displays the current phase of the game
struct CurrentPhaseLabelView: View {
    let phaseLabel: String
    var body: some View {
        HStack {
            Text("Phase:")
            Text(phaseLabel.uppercased())
        }
    }
}

#Preview {
    let phase = GamePhase.planning
    CurrentPhaseLabelView(phaseLabel: phase.description)
}
