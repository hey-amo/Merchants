import MerchantsGame
import Testing
@testable import Merchants

@Suite("Bot game presentation")
struct BotGameModelTests {
    private enum StubError: Error {
        case failed
    }

    private actor StubGame: BotGameRunning {
        let initial: GameState
        let update: BotGameUpdate?
        let shouldFail: Bool
        private var hasStepped = false

        init(initial: GameState, update: BotGameUpdate? = nil, shouldFail: Bool = false) {
            self.initial = initial
            self.update = update
            self.shouldFail = shouldFail
        }

        func snapshot() -> GameState { initial }

        func step() throws -> BotGameUpdate? {
            if shouldFail { throw StubError.failed }
            guard !hasStepped else { return nil }
            hasStepped = true
            return update
        }
    }

    @Test @MainActor func startsPausesAndResetsAGame() async throws {
        let configuration = try fixtureConfiguration()
        let initial = try GameState(configuration: configuration)
        let seat = try initial.draft.nextSeat()
        let player = configuration.playerIDs[seat]
        let action = try #require(initial.legalActions(for: player).first)
        let (afterDraft, _) = try GameEngine.apply(action, by: player, to: initial)
        let update = BotGameUpdate(state: afterDraft, message: "Stub draft")
        let model = BotGameModel(stepDelayNanoseconds: 0) { _ in
            StubGame(initial: initial, update: update)
        }

        await model.prepare(configuration: configuration)
        #expect(model.state == initial)
        model.setRunning(true)
        model.setRunning(false)
        await model.run()
        #expect(model.state == initial)

        model.setRunning(true)
        await model.run()
        #expect(model.state == afterDraft)
        #expect(model.message == "Stub draft")
        #expect(!model.isRunning)
        #expect(model.error == nil)

        await model.prepare(configuration: configuration)
        #expect(model.state == initial)
        #expect(!model.isRunning)
    }

    @Test @MainActor func reportsSessionFailureWithoutChangingState() async throws {
        let configuration = try fixtureConfiguration()
        let initial = try GameState(configuration: configuration)
        let model = BotGameModel(stepDelayNanoseconds: 0) { _ in
            StubGame(initial: initial, shouldFail: true)
        }

        await model.prepare(configuration: configuration)
        model.setRunning(true)
        await model.run()
        #expect(model.state == initial)
        #expect(model.error != nil)
        #expect(!model.isRunning)
        #expect(!model.isStepping)
    }

    @Test @MainActor func reportsSessionCreationFailure() async throws {
        let model = BotGameModel { _ in throw StubError.failed }

        await model.prepare(configuration: try fixtureConfiguration())
        #expect(model.state == nil)
        #expect(model.error != nil)
        #expect(!model.isPreparing)
        model.setRunning(true)
        #expect(!model.isRunning)
    }

    @Test @MainActor func presentsWinnersAfterBotsFinish() async throws {
        let model = BotGameModel(stepDelayNanoseconds: 0)
        await model.prepare(configuration: try fixtureConfiguration())
        model.setRunning(true)
        await model.run()

        #expect(model.state?.ending.status == .finished)
        #expect(!model.winners.isEmpty)
        #expect(!model.isRunning)
        #expect(model.error == nil)
    }

    private func fixtureConfiguration() throws -> GameConfiguration {
        try GameConfiguration(
            playerIDs: [PlayerID("First bot"), PlayerID("Second bot")],
            seed: 42
        )
    }
}
