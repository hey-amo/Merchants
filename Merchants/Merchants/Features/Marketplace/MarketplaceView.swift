//
//  MarketplaceView.swift
//  Merchants
//

import SwiftUI
import MerchantsGame

// Displays the 6 goods cards currently in the market as a 2x3 grid.
// Cards are display-only: players never take or tap them, but they have accessibility labels.
struct MarketplaceView: View {
    var goods: [GoodType] = GoodType.allCases

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(goods.enumerated()), id: \.offset) { _, good in
                GoodsCardView(good: good)
            }
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Marketplace")
    }
}

#Preview {
    MarketplaceView()
}
