//
//  GameCanvasView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI

// Display the main game canvas view

// Structure
// HUD with button (button is inactive for now)
// Main canvas area
// - Current Phase: (label) (tiny) | Cards remaining: (label) or it could be a progress bar [----]?
// - Game Message section
// - Carousel section: {
// ---- Cubes in supply
// ---- Marketplace cards (default)
// ---- Player 2 (quick overview)
// ---- Player 3 (quick overview: if in the game)
// ---- Player 4 (quick overview: if in the game)
// ---- General stats (if implemented)
// } // :endCarousel
// - Your ships (Carousel) section
// - Your special cards (Carousel) section
// - Your cards
// Footer

struct GameCanvasView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    GameCanvasView()
}
