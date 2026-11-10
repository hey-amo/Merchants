//
//  WinnerView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI
import MerchantsGame

struct WinnerView: View {
    /// How tied winners are presented.
    enum TieStyle {
        /// One card per winner in a swipeable, paged carousel with page dots.
        case carousel
        /// All winners share one hero with overlapping captain avatars.
        case combined
    }

    let winners: [PlayerViewModel]
    let runnersUp: [PlayerViewModel]
    var tieStyle: TieStyle = .carousel
    var onPlayAgain: () -> Void = {}

    @State private var carouselSelection: PlayerViewModel.ID?

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
        .safeAreaInset(edge: .bottom) {
            Button(action: onPlayAgain) {
                Text("Play again")
                    .font(.headline)
                    .frame(maxWidth: 320)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.bar)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Play again", action: onPlayAgain)
            }
        }
    }

    private var isTie: Bool { winners.count > 1 }

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

            if isTie && tieStyle == .combined {
                combinedWinnersCard
            } else if isTie {
                winnersCarousel
            } else {
                ForEach(winners) { winnerCard($0) }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func winnerCard(_ player: PlayerViewModel) -> some View {
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

    // Paged carousel with page dots, as the HIG recommends for a small set of paged items.
    private var winnersCarousel: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(winners) { player in
                        winnerCard(player)
                            .containerRelativeFrame(.horizontal, count: 1, spacing: 12)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $carouselSelection)
            .scrollIndicators(.hidden)

            HStack(spacing: 8) {
                ForEach(winners) { player in
                    Circle()
                        .fill(player.id == (carouselSelection ?? winners.first?.id) ? Color.primary : Color.secondary.opacity(0.35))
                        .frame(width: 8, height: 8)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Winner \(currentCarouselPage + 1) of \(winners.count)")
        }
    }

    private var currentCarouselPage: Int {
        winners.firstIndex { $0.id == carouselSelection } ?? 0
    }

    // All tied winners in one hero, captains slightly overlapping.
    private var combinedWinnersCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: -20) {
                ForEach(Array(winners.enumerated()), id: \.element.id) { index, player in
                    PlayerAvatarView(avatarIndex: player.avatarIndex, state: .onTurn)
                        .frame(height: 96)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color(.systemBackground), lineWidth: 3)
                        }
                        .zIndex(Double(winners.count - index))
                }
            }
            .accessibilityHidden(true)

            Text("\(winners.map(\.name).joined(separator: ", ")) all got:")
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            CoinValueView(value: winners.first?.coins ?? 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(winners.map(\.name).joined(separator: ", ")) all got \(winners.first?.coins ?? 0) coins")
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
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
    NavigationStack {
        WinnerView(
            winners: [PlayerViewModel(name: "You", coins: 120, isHuman: true, avatarIndex: 0)],
            runnersUp: [
                PlayerViewModel(name: BotNames.name(forBot: 1), coins: 95, avatarIndex: 1),
                PlayerViewModel(name: BotNames.name(forBot: 2), coins: 75, avatarIndex: 2)
            ]
        )
    }
}

#Preview("Bot winner") {
    NavigationStack {
        WinnerView(
            winners: [PlayerViewModel(name: BotNames.name(forBot: 2), coins: 120, avatarIndex: 2)],
            runnersUp: [
                PlayerViewModel(name: "You", coins: 95, isHuman: true, avatarIndex: 0),
                PlayerViewModel(name: BotNames.name(forBot: 1), coins: 75, avatarIndex: 1)
            ]
        )
    }
}

private let tiedWinners = [
    PlayerViewModel(name: "You", coins: 120, isHuman: true, avatarIndex: 0),
    PlayerViewModel(name: BotNames.name(forBot: 1), coins: 120, avatarIndex: 1),
    PlayerViewModel(name: BotNames.name(forBot: 2), coins: 120, avatarIndex: 2),
    PlayerViewModel(name: BotNames.name(forBot: 3), coins: 120, avatarIndex: 2)
]

#Preview("Tied winners - carousel") {
    NavigationStack {
        WinnerView(
            winners: tiedWinners,
            runnersUp: [PlayerViewModel(name: BotNames.name(forBot: 3), coins: 75, avatarIndex: 3)],
            tieStyle: .carousel
        )
    }
}

#Preview("Tied winners - combined") {
    NavigationStack {
        WinnerView(
            winners: tiedWinners,
            runnersUp: [PlayerViewModel(name: BotNames.name(forBot: 3), coins: 75, avatarIndex: 3)],
            tieStyle: .combined
        )
    }
}
