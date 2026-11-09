import Foundation
import MerchantsGame
import Observation

struct BotGameUpdate: Sendable {
    let state: GameState
    let message: String
}

protocol BotGameRunning: Sendable {
    func snapshot() async -> GameState
    func step() async throws -> BotGameUpdate?
}

private struct LiveBotGame: BotGameRunning {
    let session: BotGameSession

    func snapshot() async -> GameState {
        await session.snapshot()
    }

    func step() async throws -> BotGameUpdate? {
        guard let step = try await session.step() else { return nil }
        return BotGameUpdate(state: step.state, message: step.message)
    }
}

@MainActor
@Observable
final class BotGameModel {
    private(set) var state: GameState?
    private(set) var message = "Preparing a game..."
    private(set) var error: String?
    private(set) var winners: [PlayerID] = []
    private(set) var isRunning = false
    private(set) var isStepping = false
    private(set) var isPreparing = false
    private let stepDelayNanoseconds: UInt64
    private let makeSession: (GameConfiguration) throws -> any BotGameRunning
    private var session: (any BotGameRunning)?

    init(
        stepDelayNanoseconds: UInt64 = 350_000_000,
        makeSession: @escaping (GameConfiguration) throws -> any BotGameRunning = {
            LiveBotGame(session: try BotGameSession(configuration: $0))
        }
    ) {
        self.stepDelayNanoseconds = stepDelayNanoseconds
        self.makeSession = makeSession
    }

    func prepare(configuration: GameConfiguration? = nil) async {
        guard !isPreparing, !isStepping else { return }
        isPreparing = true
        defer { isPreparing = false }
        isRunning = false
        do {
            let configuration = try configuration ?? GameConfiguration.randomSeeded(
                playerIDs: [PlayerID("Bot 1"), PlayerID("Bot 2")]
            )
            let newSession = try makeSession(configuration)
            let initialState = await newSession.snapshot()
            session = newSession
            state = initialState
            winners = []
            error = nil
            message = "Ready to begin the cube draft."
        } catch {
            session = nil
            state = nil
            self.error = String(describing: error)
        }
    }

    func setRunning(_ running: Bool) {
        guard session != nil, error == nil, !isStepping,
              state?.ending.status != .finished else { return }
        isRunning = running
    }

    func run() async {
        guard let session, isRunning else { return }
        while isRunning && !Task.isCancelled {
            isStepping = true
            let step: BotGameUpdate?
            do {
                step = try await session.step()
                isStepping = false
            } catch is CancellationError {
                isStepping = false
                return
            } catch {
                self.error = String(describing: error)
                isRunning = false
                isStepping = false
                return
            }

            guard let step else {
                isRunning = false
                return
            }
            state = step.state
            message = step.message
            if step.state.ending.status == .finished {
                do {
                    winners = try step.state.ending.standings(
                        players: step.state.configuration.playerIDs,
                        bank: step.state.bank
                    ).winners
                } catch {
                    self.error = String(describing: error)
                }
                isRunning = false
                return
            }

            do {
                try await Task.sleep(nanoseconds: stepDelayNanoseconds)
            } catch is CancellationError {
                return
            } catch {
                self.error = String(describing: error)
                isRunning = false
                return
            }
        }
    }
}
