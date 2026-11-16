import Testing
@testable import MerchantsGame

@Suite("Bot game session")
struct BotGameSessionTests {
    @Test(arguments: [
        (2, UInt64(42), EndGameRule.immediate, StrategistPersonality.aggressive),
        (2, UInt64(42), .oneMoreTurn, .conservative),
        (3, UInt64(9), .oneMoreTurn, .aggressive),
        (4, UInt64(31), .oneMoreTurn, .conservative)
    ])
    func botsPlayFromDraftToGameOver(
        count: Int, seed: UInt64, rule: EndGameRule, personality: StrategistPersonality
    ) async throws {
        let players = (1...count).map { PlayerID("Bot \($0)") }
        let rules = try GameRules(specialCardCatalog: .standard, endGameRule: rule)
        let configuration = try GameConfiguration(playerIDs: players, seed: seed, rules: rules)
        let session = try BotGameSession(
            configuration: configuration, personality: personality, logger: { _ in }
        )
        var state = await session.snapshot()
        var actions = 0
        var draftActions = 0
        var planningActions = 0
        var tradingActions = 0

        while state.ending.status != .finished && actions < 1_000 {
            let step = try #require(try await session.step())
            let legalActions = try state.legalActions(for: step.player)
            #expect(legalActions.contains(step.action))
            let (expected, _) = try GameEngine.apply(step.action, by: step.player, to: state)
            #expect(step.state == expected)
            #expect(!step.message.isEmpty)
            if state.turn == nil {
                draftActions += 1
            } else if case .active(.trading) = state.turn?.status {
                tradingActions += 1
            } else {
                planningActions += 1
            }
            state = step.state
            actions += 1
        }

        #expect(state.ending.status == .finished)
        #expect(draftActions == players.count * 2)
        #expect(planningActions > 0)
        #expect(tradingActions > 0)
        #expect(try state.ending.standings(players: players, bank: state.bank).winners.isEmpty == false)
        #expect(try await session.step() == nil)
    }

    @Test func cancellationBeforeStepLeavesTheSessionUnchanged() async throws {
        let players = [PlayerID("First"), PlayerID("Second")]
        let configuration = try GameConfiguration(playerIDs: players, seed: 42)
        let session = try BotGameSession(configuration: configuration, logger: { _ in })
        let initial = await session.snapshot()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await session.step()
        }

        do {
            _ = try await task.value
            Issue.record("A cancelled bot action must not run")
        } catch is CancellationError {
            #expect(await session.snapshot() == initial)
        }
        #expect(try await session.step() != nil)
    }

    @Test(arguments: 0..<12)
    func variedSeededGamesReachTheEnd(seed: Int) async throws {
        let players = (1...(2 + seed % 3)).map { PlayerID("Bot \($0)") }
        let configuration = try GameConfiguration(playerIDs: players, seed: UInt64(seed))
        let session = try BotGameSession(
            configuration: configuration,
            personality: seed.isMultiple(of: 2) ? .aggressive : .conservative,
            logger: { _ in }
        )
        var state = await session.snapshot()
        var actions = 0
        while state.ending.status != .finished && actions < 1_000 {
            state = try #require(try await session.step()).state
            actions += 1
        }
        #expect(state.ending.status == .finished)
    }
}
