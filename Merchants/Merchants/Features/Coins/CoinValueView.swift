// CoinValueView.swift
import SwiftUI

// A partial view showing only coins
struct CoinValueView: View {
    let value: Int

    var body: some View {
        HStack(spacing: 6) {
            Image("coin-single")
            Text(value, format: .number)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Coins: \(value)"))
    }
}

#Preview {
    CoinValueView(value: 120)
        .padding()
}
