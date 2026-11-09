//
//  WinnerView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI
import MerchantsGame

struct WinnerView: View {
    let winners: [WinnerPlayerModel]
    let runnersUp: [WinnerPlayerModel]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                hero

                if !runnersUp.isEmpty {
                    runnersUpSection
                }
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
        }
        .background {
            LinearGradient(
                colors: [.orange.opacity(0.16), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }

    private var hero: some View {
        VStack(spacing: 16) {
            Text("🏆")
                .font(.system(size: 64))
                .accessibilityHidden(true)

            Text(winners.isEmpty ? "Results unavailable" : winners.count == 1 ? "We have a winner!" : "It's a tie!")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            if !winners.isEmpty {
                Text(winners.count == 1 ? "The winning merchant" : "The winning merchants")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(winners) { player in
                VStack(spacing: 8) {
                    Text("🤖")
                        .font(.largeTitle)
                        .accessibilityHidden(true)
                    Text(player.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    CoinValueView(value: player.coins)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var runnersUpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Runners up")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            ForEach(runnersUp) { player in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("🤖")
                            .accessibilityHidden(true)
                        Text(player.name)
                            .font(.headline)
                    }
                    CoinValueView(value: player.coins)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Solo winner") {
    WinnerView(
        winners: [WinnerPlayerModel(name: "Bot 1", coins: 120)],
        runnersUp: [
            WinnerPlayerModel(name: "Bot 2", coins: 95),
            WinnerPlayerModel(name: "Bot 3", coins: 75)
        ]
    )
}

#Preview("Tied winners") {
    WinnerView(
        winners: [
            WinnerPlayerModel(name: "Bot 1", coins: 120),
            WinnerPlayerModel(name: "Bot 2", coins: 120)
        ],
        runnersUp: [WinnerPlayerModel(name: "Bot 3", coins: 75)]
    )
}
