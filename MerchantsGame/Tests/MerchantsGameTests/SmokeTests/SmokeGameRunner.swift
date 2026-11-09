import Foundation
@testable import MerchantsGame

enum SmokeGameError: Error, Equatable, CustomStringConvertible {
    case invalidRoundLimit
    case invalidDelay
    case unexpectedEnd

    var description: String {
        switch self {
        case .invalidRoundLimit: "SMOKE_ROUNDS must be an integer from 1 to 10."
        case .invalidDelay: "SMOKE_DELAY_MS must be an integer from 0 to 10000."
        case .unexpectedEnd: "The session ended unexpectedly before the smoke test stopped."
        }
    }
}

protocol SmokeSession: Sendable {
    func snapshot() async -> GameState
    func step() async throws -> BotGameStep?
}

extension BotGameSession: SmokeSession {}

struct SmokeGameRunner {
    enum StopReason: Equatable {
        case roundLimit
        case deckEmpty
        case gameFinished
    }

    struct Result: Equatable {
        let completedRounds: Int
        let reason: StopReason
    }

    let session: any SmokeSession
    let roundLimit: Int
    let delay: @Sendable () async throws -> Void
    let log: @Sendable (String) async -> Void

    func run() async throws -> Result {
        guard (1...10).contains(roundLimit) else { throw SmokeGameError.invalidRoundLimit }
        var state = await session.snapshot()
        var completedRounds = 0
        await log("=== Smoke game session started ===\nPlayers: \(state.configuration.playerIDs.map(\.rawValue).joined(separator: ", "))\nSeed: \(state.configuration.seed)\nLimit: \(roundLimit) round(s)")

        while true {
            try Task.checkCancellation()
            let reason: StopReason?
            if state.deck.remaining == 0 {
                reason = .deckEmpty
            } else if state.ending.status == .finished {
                reason = .gameFinished
            } else if completedRounds == roundLimit {
                reason = .roundLimit
            } else {
                reason = nil
            }
            if let reason {
                await log("=== Smoke game stopped: \(stopDescription(reason)); \(completedRounds) round(s) completed ===")
                return Result(completedRounds: completedRounds, reason: reason)
            }

            let seat: Int
            if let turn = state.turn {
                seat = turn.currentSeat
            } else {
                seat = try state.draft.nextSeat()
            }
            let player = state.configuration.playerIDs[seat]
            let view = try state.playerView(for: player)
            let phase: String
            if let turn = view.turn {
                switch turn.status {
                case .active(.planning): phase = "Planning"
                case .active(.trading): phase = "Trading"
                case .notStarted, .finished: throw SmokeGameError.unexpectedEnd
                }
            } else {
                phase = "Draft"
            }
            let market = view.marketplaceCards.map { String(describing: $0.good).capitalized }
                .joined(separator: ", ")
            let supply = GoodType.allCases.map {
                "\(String(describing: $0).capitalized): \(view.supply.available(of: $0))"
            }.joined(separator: ", ")
            let ships = view.fleets[seat].ships.enumerated().map { index, ship in
                let cubes = ship.cubes.map { String(describing: $0.good).capitalized }
                return "  Ship \(index + 1) (\(String(describing: ship.kind))): \(cubes.isEmpty ? "empty" : cubes.joined(separator: ", "))"
            }.joined(separator: "\n")
            let hand = view.hand.map { String(describing: $0.good).capitalized }.joined(separator: ", ")
            await log("\n--- \(phase): \(player.rawValue) ---\nMarketplace: \(market)\nDeck remaining: \(view.deckCount)\nCube supply: \(supply)\n\(player.rawValue)'s portfolio:\n\(ships)\n  Hand: \(hand.isEmpty ? "empty" : hand)")

            try await delay()
            try Task.checkCancellation()
            guard let step = try await session.step() else { throw SmokeGameError.unexpectedEnd }
            state = step.state
            if case .draftCube(let good, let ship) = step.action {
                await log("Decision: \(player.rawValue) drafted \(String(describing: good).capitalized) for ship \(ship + 1).")
            } else {
                await log("Decision: \(step.message)")
            }
            switch step.action {
            case .drawCards, .deliverCards, .skipTrading:
                completedRounds += 1
                await log("Round \(completedRounds) completed.")
            default:
                break
            }
        }
    }

    private func stopDescription(_ reason: StopReason) -> String {
        switch reason {
        case .roundLimit: "round limit reached"
        case .deckEmpty: "deck empty"
        case .gameFinished: "game finished"
        }
    }
}
