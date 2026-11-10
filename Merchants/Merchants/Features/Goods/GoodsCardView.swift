//
//  GoodsCardView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI
import MerchantsGame

// Single goods card with its name underneath. Read-only: cards are never tapped.
struct GoodsCardView: View {
    let good: GoodType

    // Space between the card edge and the goods artwork.
    private let cardInset: CGFloat = 10

    var body: some View {
        VStack(spacing: 4) {
            Image("crate-card")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .overlay {
                    Image(good.goodsImageName)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .padding(cardInset)
                }
            Text(good.displayName)
                .font(.caption)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(good.displayName) goods card")
    }
}

#Preview {
    GoodsCardView(good: .tea)
        .frame(width: 100)
}
