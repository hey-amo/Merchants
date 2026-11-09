// Tests FR1 configuration validation, defaults, and serialization.
// Owns coverage for supported counts, unique identities, and first-player choice.
// Does not test deck setup, gameplay, or tunable rule behavior.

import Foundation
import XCTest
@testable import MerchantsGame

final class GameConfigurationTests: XCTestCase {
    func testAcceptsPlayerCountsTwoThreeAndFour() throws {
        for count in [2, 3, 4] {
            let configuration = try GameConfiguration(
                playerIDs: playerIDs(count),
                seed: 42
            )

            XCTAssertEqual(configuration.playerIDs.count, count)
            XCTAssertEqual(configuration.seed, 42)
            XCTAssertEqual(configuration.firstPlayer, .random)
            XCTAssertEqual(configuration.rules, .standard)
        }
    }

    func testRejectsOneAndFivePlayers() {
        for count in [1, 5] {
            XCTAssertThrowsError(
                try GameConfiguration(playerIDs: playerIDs(count), seed: 42)
            ) {
                XCTAssertEqual($0 as? GameSetupError, .invalidPlayerCount)
            }
        }
    }

    func testRejectsDuplicatePlayerIDs() {
        XCTAssertThrowsError(
            try GameConfiguration(
                playerIDs: [PlayerID("same"), PlayerID("same")],
                seed: 42
            )
        ) {
            XCTAssertEqual($0 as? GameSetupError, .duplicatePlayerID)
        }
    }

    func testRejectsUnknownFixedFirstPlayer() {
        XCTAssertThrowsError(
            try GameConfiguration(
                playerIDs: playerIDs(2),
                seed: 42,
                firstPlayer: .fixed(PlayerID("unknown"))
            )
        ) {
            XCTAssertEqual($0 as? GameSetupError, .unknownFirstPlayer)
        }
    }

    func testAcceptsFixedFirstPlayerFromSeating() throws {
        let ids = playerIDs(2)
        let configuration = try GameConfiguration(
            playerIDs: ids,
            seed: 42,
            firstPlayer: .fixed(ids[1])
        )

        XCTAssertEqual(configuration.firstPlayer, .fixed(ids[1]))
    }

    func testRandomSeededFactoryCreatesSerializableConfiguration() throws {
        let ids = playerIDs(2)
        let configuration = try GameConfiguration.randomSeeded(playerIDs: ids)
        let data = try JSONEncoder().encode(configuration)
        let decoded = try JSONDecoder().decode(GameConfiguration.self, from: data)

        XCTAssertEqual(decoded.playerIDs, ids)
        XCTAssertEqual(decoded.seed, configuration.seed)
        XCTAssertEqual(decoded.firstPlayer, .random)
        XCTAssertEqual(decoded.rules, .standard)
    }

    func testDecodingRejectsDuplicatePlayerIDs() throws {
        let valid = try GameConfiguration(playerIDs: playerIDs(2), seed: 42)
        let encoded = try JSONEncoder().encode(valid)
        var object = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        object["playerIDs"] = ["duplicate", "duplicate"]
        let invalidData = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(
            try JSONDecoder().decode(GameConfiguration.self, from: invalidData)
        ) {
            XCTAssertEqual($0 as? GameSetupError, .duplicatePlayerID)
        }
    }

    private func playerIDs(_ count: Int) -> [PlayerID] {
        (0..<count).map { PlayerID("player-\($0)") }
    }
}
