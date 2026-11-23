//
//  GameSetupView.swift
//  Merchants
//

import SwiftUI
import MerchantsGame

/// Local setup for who is playing.
///
/// Players can be added, removed, and switched between human and bot.
/// One human is always kept. Continue stays disabled until there are
/// at least two players, including that human.

// MARK: - Model

private enum PlayerKind: CaseIterable, Identifiable, Sendable {
    case human, bot

    var id: Self { self }

    var title: String {
        switch self {
        case .human: "Human"
        case .bot: "Bot"
        }
    }

    var symbol: String {
        switch self {
        case .human: "👩"
        case .bot: "🤖"
        }
    }

    var toggled: Self {
        switch self {
        case .human: .bot
        case .bot: .human
        }
    }
}

private struct SetupPlayer: Identifiable {
    let id = UUID()
    var kind: PlayerKind
    var avatarIndex: Int
}

// MARK: - Screen

struct GameSetupView: View {
    fileprivate static let avatarName = "captains"
    fileprivate static let avatarCount = 5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var players = Self.openingPlayers

    private var humanCount: Int {
        players.filter { $0.kind == .human }.count
    }

    private var canAdd: Bool {
        players.count < PlayerCount.range.upperBound
    }

    private var canContinue: Bool {
        players.count >= PlayerCount.range.lowerBound && humanCount >= 1
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                header
                playerSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            continueBar
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Offline mode")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Start new game")
                .font(.largeTitle.weight(.bold))
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Text("Select players (2-4)")
                    .font(.title3.weight(.semibold))
                Spacer(minLength: 8)
            }

            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                SetupPlayerRow(
                    name: "Player \(index + 1)",
                    kind: player.kind,
                    avatarIndex: player.avatarIndex,
                    canToggle: canToggle(player),
                    canRemove: canRemove(player),
                    onCycleAvatar: { cycleAvatar(player.id) },
                    onToggle: { toggle(player.id) },
                    onRemove: { remove(player.id) }
                )
            }
            
            HStack {
                Spacer(minLength: 0)
                RoundIconButton(
                    systemImage: "plus",
                    isEnabled: canAdd,
                    label: "Add player",
                    hint: canAdd ? "Adds another player" : "A game can have up to \(PlayerCount.range.upperBound) players",
                    action: addPlayer
                )
            }
        }
    }

    private var continueBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                print("Game setup complete")
            } label: {
                HStack(spacing: 6) {
                    Text("Continue")
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.bold))
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canContinue)
            .accessibilityHint(continueHint)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(.background)
    }

    private var continueHint: String {
        if players.count < PlayerCount.range.lowerBound {
            "Add at least two players to continue"
        } else if humanCount < 1 {
            "Add a human player to continue"
        } else {
            "Confirms these players"
        }
    }

    private func canToggle(_ player: SetupPlayer) -> Bool {
        player.kind == .bot || humanCount > 1
    }

    private func canRemove(_ player: SetupPlayer) -> Bool {
        player.kind == .bot || humanCount > 1
    }

    private func addPlayer() {
        guard canAdd else { return }
        let used = Set(players.map(\.avatarIndex))
        let avatar = (0..<Self.avatarCount).first { !used.contains($0) } ?? 0
        let kind: PlayerKind = humanCount == 0 ? .human : .bot
        change {
            players.append(SetupPlayer(kind: kind, avatarIndex: avatar))
        }
    }

    private func remove(_ id: UUID) {
        guard let player = players.first(where: { $0.id == id }), canRemove(player) else { return }
        change {
            players.removeAll { $0.id == id }
        }
    }

    private func toggle(_ id: UUID) {
        guard let index = players.firstIndex(where: { $0.id == id }), canToggle(players[index]) else { return }
        change {
            players[index].kind = players[index].kind.toggled
        }
    }

    private func cycleAvatar(_ id: UUID) {
        guard let index = players.firstIndex(where: { $0.id == id }) else { return }
        let used = Set(players.enumerated().compactMap { $0.offset == index ? nil : $0.element.avatarIndex })
        var next = players[index].avatarIndex
        for _ in 0..<Self.avatarCount {
            next = (next + 1) % Self.avatarCount
            if !used.contains(next) { break }
        }
        change {
            players[index].avatarIndex = next
        }
    }

    private func change(_ update: () -> Void) {
        if reduceMotion {
            update()
        } else {
            withAnimation(.snappy) { update() }
        }
    }

    private static var openingPlayers: [SetupPlayer] {
        (0..<PlayerCount.range.upperBound).map { index in
            SetupPlayer(
                kind: index.isMultiple(of: 2) ? .human : .bot,
                avatarIndex: index
            )
        }
    }
}

// MARK: - Row

private struct SetupPlayerRow: View {
    let name: String
    let kind: PlayerKind
    let avatarIndex: Int
    let canToggle: Bool
    let canRemove: Bool
    let onCycleAvatar: () -> Void
    let onToggle: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onCycleAvatar) {
                CaptainAvatarImg(
                    name: GameSetupView.avatarName,
                    count: GameSetupView.avatarCount,
                    index: avatarIndex
                )
                .frame(height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(name) captain")
            .accessibilityHint("Shows another captain")

            Text(name)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Button(action: onToggle) {
                Text(kind.symbol)
                    .font(.title)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .disabled(!canToggle)
            .accessibilityLabel(kind.title)
            .accessibilityHint(canToggle ? "Switches between human and bot" : "At least one human is required")

            Spacer(minLength: 8)

            RoundIconButton(
                systemImage: "minus",
                isEnabled: canRemove,
                label: "Remove \(name)",
                hint: canRemove ? "Removes this player" : "At least one human is required",
                action: onRemove
            )
        }
        .accessibilityElement(children: .contain)
    }
}

private struct RoundIconButton: View {
    let systemImage: String
    var isEnabled = true
    let label: String
    let hint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(isEnabled ? 1 : 0.35), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
        .accessibilityHint(hint)
    }
}

#Preview {
    NavigationStack {
        GameSetupView()
    }
}
