//
//  MainMenuView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI

// Fix: Blue background
// Ship blue bg: RGB: {98, 222, 253}, hex: 62defd
// Fix button to contrast against blue bg

// Buttons:
// - Play offline game (confirms if there's a game existing)
// - Continue game (greyed out if no game exists)
// - Game center (not implemented)
// - Sound/Music toggle buttons
// - About (not implemented)

struct MainMenuView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image("ship-nobg")
                Text("Merchants")
                    .font(.largeTitle)
                NavigationLink("Watch a bot game", value: Route.botGame)
                    .buttonStyle(.borderedProminent)
            }
            .background(.blue) // needs to be full screen colour
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .botGame:
                    BotGameView()
                }
            }
        }
    }

    private enum Route: Hashable {
        case botGame
    }
}

#Preview {
    MainMenuView()
}
