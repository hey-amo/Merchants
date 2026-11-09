import Foundation
import Testing
@testable import MerchantsGame

@Suite("Interactive bot smoke test")
struct SmokeGameTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["SMOKE_ROUNDS"] != nil))
    func runBotGame() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let value = environment["SMOKE_ROUNDS"],
              let rounds = Int(value), (1...10).contains(rounds) else {
            throw SmokeGameError.invalidRoundLimit
        }
        let delayValue = environment["SMOKE_DELAY_MS"] ?? "2000"
        guard let milliseconds = UInt64(delayValue), milliseconds <= 10_000 else {
            throw SmokeGameError.invalidDelay
        }
        let configuration = try GameConfiguration(
            playerIDs: [PlayerID("Bot 1"), PlayerID("Bot 2")],
            seed: 42
        )
        let session = try BotGameSession(configuration: configuration, logger: { _ in })
        let runner = SmokeGameRunner(
            session: session,
            roundLimit: rounds,
            delay: { try await Task.sleep(nanoseconds: milliseconds * 1_000_000) },
            log: { print($0) }
        )
        _ = try await runner.run()
    }
}
