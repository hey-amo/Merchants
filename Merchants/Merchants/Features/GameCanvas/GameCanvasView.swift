//
//  GameCanvasView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI
import MerchantsGame

// Display the main game canvas view

// Structure: Full size screen (iPhone portrait)
// Scrollview {
// - Sticky HUD bar [List players | notification bell | hamburger menu
//
// - (small spacing)
// - Current Phase: (label) (tiny) | Cards remaining: (label)
// - Last game message section
//
// - Carousel section: {
// ---- Crates in supply
// ---- Marketplace cards (default)
// ---- Player 2 (quick overview)
// ---- Player 3 (quick overview: if in the game)
// ---- Player 4 (quick overview: if in the game)
// ---- General stats (if implemented)
// } // :endCarousel
//
// - Carousel section: {
// ---- Your ships section
// ---- Your special cards
// }
//
// - Your cards (hand of cards move left to right, selectable)
// Footer (not used yet)
// }

struct GameCanvasView: View {        
    var body: some View {
        Text("Hello world)")
    }
}


private struct CarouselView: View {
    var body: some View {
        Text("Hello world")
    }
}

#Preview {
    GameCanvasView(
    )
}
