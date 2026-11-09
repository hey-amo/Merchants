import SwiftUI

// A partial showing only coins
struct CoinValueView: View {
    let value: Int

    var body: some View {
        HStack(spacing: 6) {
            Text("🪙")
                .accessibilityHidden(true)
            Text(value, format: .number)
                .monospacedDigit()
            Text("coins")
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Coins: \(value)"))
    }
}

#Preview {
    CoinValueView(value: 120)
        .padding()
}
