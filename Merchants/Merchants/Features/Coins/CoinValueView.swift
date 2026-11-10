// CoinValueView.swift
import SwiftUI

// A partial view showing only the coins
// Has adjustible font size
struct CoinValueView: View {
    let value: Int
    var fontSize: CGFloat = 24

    var body: some View {
        HStack(spacing: 6) {
            Image("coin-single")
            Text(value, format: .number)
                .font(.system(size: fontSize))
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Coins: \(value)"))
    }
}

#Preview {
    CoinValueView(value: 120)
}
