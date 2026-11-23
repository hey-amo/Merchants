////
//  CardsLeftInDeckView.swift
//  Merchants
//
//  Created by AD on 23/11/2026.
//

// Display a graphic and cards left in the deck (count)
import SwiftUI
import MerchantsGame

// Displays the number of cards left in the deck as a stacked card graphic
struct CardsLeftInDeckView: View {
    let cardsLeft: UInt32

    private let maxVisibleLayers = 3
    private let layerSpacing: CGFloat = 4
    private let cardWidth: CGFloat = 80

    /// Number of stacked card images to draw. Always at least 1 so an empty deck still shows a placeholder.
    private var layerCount: Int {
        max(1, min(Int(cardsLeft), maxVisibleLayers))
    }

    private var isEmpty: Bool {
        cardsLeft == 0
    }

    var body: some View {
        ZStack {
            // Draw back to front. The front card (index 0) is drawn last, so it sits on top.
            ForEach((0..<layerCount).reversed(), id: \.self) { depth in
                Image("card-small")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: cardWidth)
                    .overlay {
                        if depth == 0 {
                            countLabel
                        }
                    }
                    .offset(
                        x: CGFloat(depth) * layerSpacing,
                        y: -CGFloat(depth) * layerSpacing
                    )
            }
        }
        .grayscale(isEmpty ? 1 : 0)
        .opacity(isEmpty ? 0.4 : 1)
        .animation(.easeInOut(duration: 0.25), value: layerCount)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(cardsLeft) \(cardsLeft == 1 ? "card" : "cards") left in deck")
    }

    private var countLabel: some View {
        Text("\(cardsLeft)")
            .font(.largeTitle)
            .monospacedDigit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("30 cards") {
    CardsLeftInDeckView(cardsLeft: 30)
        .padding(40)
}

#Preview("Stack sizes") {
    HStack(spacing: 32) {
        ForEach([3, 2, 1, 0] as [UInt32], id: \.self) { count in
            VStack {
                CardsLeftInDeckView(cardsLeft: count)
                Text("\(count) left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding(40)
}
