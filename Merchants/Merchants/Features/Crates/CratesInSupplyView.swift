//
//  CratesInSupply.swift
//  Merchants
//

import SwiftUI
import MerchantsGame

// Display all crates in supply in a flexible grid.
// Every good is always shown; an empty stock is greyed out.
struct CratesInSupplyView: View {
    let supply: CubeSupply
    /// Called when the player taps a crate (phase 1 exchange selection, not yet implemented).
    var onSelect: (GoodType) -> Void = { _ in }

    private let columns = [GridItem(.adaptive(minimum: 72), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(GoodType.allCases, id: \.self) { good in
                let count = max(supply.available(of: good), 0)
                Button { onSelect(good) } label: {
                    VStack(spacing: 4) {
                        SingleCrateView(resourceImage: good.crateImageName)
                            .frame(maxHeight: 64)
                        Text(count, format: .number)
                            .font(.headline)
                            .monospacedDigit()
                    }
                    .saturation(count == 0 ? 0 : 1)
                    .opacity(count == 0 ? 0.4 : 1)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(good.displayName) crate")
                .accessibilityValue(count == 0 ? "Out of stock" : "\(count) in stock")
                .accessibilityHint("Selects this crate")
            }
        }
        .padding()
    }
}

#Preview {
    var supply = CubeSupply()
    for _ in 0..<CubeSupply.cubesPerGood { _ = try? supply.take(.tea) }
    _ = try? supply.take(.silk)
    return CratesInSupplyView(supply: supply)
}
