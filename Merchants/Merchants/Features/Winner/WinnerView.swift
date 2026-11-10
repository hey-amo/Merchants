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

    private var headline: String {
        guard let first = winners.first else { return "Results unavailable" }
        guard winners.count == 1 else { return "It's a tie!" }
        return first.isHuman ? "You won!" : "\(first.name) won!"
    }

    private var hero: some View {
        VStack(spacing: 16) {
            Text("🏆")
                .font(.system(size: 64))
                .accessibilityHidden(true)

            Text(headline)
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
                    PlayerAvatarView(avatarIndex: player.avatarIndex, state: .onTurn)
                        .frame(height: 96)
                        .accessibilityHidden(true)
                    HStack(spacing: 6) {
                        Text(player.kindEmoji)
                            .accessibilityHidden(true)
                        Text(player.name)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                    }
                    CoinValueView(value: player.coins)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(player.name), \(player.kindLabel), \(player.coins) coins")
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
                HStack(spacing: 12) {
                    PlayerAvatarView(avatarIndex: player.avatarIndex, state: .idle)
                        .frame(height: 48)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(player.kindEmoji)
                                .accessibilityHidden(true)
                            Text(player.name)
                                .font(.headline)
                        }
                        CoinValueView(value: player.coins)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(player.name), \(player.kindLabel), \(player.coins) coins")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Human winner") {
    WinnerView(
        winners: [WinnerPlayerModel(name: "You", coins: 120, isHuman: true, avatarIndex: 0)],
        runnersUp: [
            WinnerPlayerModel(name: BotNames.name(forBot: 1), coins: 95, avatarIndex: 1),
            WinnerPlayerModel(name: BotNames.name(forBot: 2), coins: 75, avatarIndex: 2)
        ]
    )
}

#Preview("Bot winner") {
    WinnerView(
        winners: [WinnerPlayerModel(name: BotNames.name(forBot: 2), coins: 120, avatarIndex: 2)],
        runnersUp: [
            WinnerPlayerModel(name: "You", coins: 95, isHuman: true, avatarIndex: 0),
            WinnerPlayerModel(name: BotNames.name(forBot: 1), coins: 75, avatarIndex: 1)
        ]
    )
}

#Preview("Tied winners") {
    WinnerView(
        winners: [
            WinnerPlayerModel(name: BotNames.name(forBot: 1), coins: 120, avatarIndex: 1),
            WinnerPlayerModel(name: "You", coins: 120, isHuman: true, avatarIndex: 0)
        ],
        runnersUp: [WinnerPlayerModel(name: BotNames.name(forBot: 3), coins: 75, avatarIndex: 3)]
    )
}
