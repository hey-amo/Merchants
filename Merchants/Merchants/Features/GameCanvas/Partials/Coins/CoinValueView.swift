// CoinValueView.swift
import SwiftUI

// A partial view showing only the coins
// Has adjustible font size
struct CoinValueView: View {
    let value: Int
    var fontSize: CGFloat = 18

    var body: some View {
        HStack(spacing: 6) {
            Image("coin-single").resizable().frame(width:30, height: 30)
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
