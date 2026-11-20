//
//  GameSetupView.swift
//  Merchants
//

import SwiftUI

/// Display the game setup screen
///
/// Show list of avatars to play as
/// Toggle human/AI players
///
struct GameSetupView: View {
    var body: some View {
        VStack {
            Text("Local game").font(.caption)
            Text("Create new game").font(.largeTitle)
            Text("Select players").font(.title)
        }
        // List available captains
    }
}

#Preview {
    GameSetupView()
}
