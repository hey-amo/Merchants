// Tests FR2 seeded generation, deterministic shuffling, selection, and restoration.
// Owns coverage for stable SplitMix64 output and repeatable setup randomness.
// Does not test deck composition or full game-state setup.

import Foundation
import XCTest
@testable import MerchantsGame

final class SeededRandomSourceTests: XCTestCase {
    func testSplitMix64GoldenValues() {
        var random = SeededRandomSource(seed: 0)

        XCTAssertEqual(random.next(), 0xE220A8397B1DCDAF)
        XCTAssertEqual(random.next(), 0x6E789E6AA1B965F4)
        XCTAssertEqual(random.next(), 0x06C45D188009454F)
    }

    func testSameSeedProducesIdenticalShuffleAndFirstPlayer() throws {
        let players = (0..<4).map { PlayerID("player-\($0)") }
        let configuration = try GameConfiguration(
            playerIDs: players,
            seed: 1234
        )
        var firstRandom = SeededRandomSource(seed: configuration.seed)
        var secondRandom = SeededRandomSource(seed: configuration.seed)
        var firstDeck = Array(0..<60)
        var secondDeck = Array(0..<60)

        firstRandom.shuffle(&firstDeck)
        secondRandom.shuffle(&secondDeck)
        let firstPlayer = firstRandom.firstPlayer(in: configuration)
        let repeatedFirstPlayer = secondRandom.firstPlayer(in: configuration)

        XCTAssertEqual(firstDeck, secondDeck)
        XCTAssertEqual(firstPlayer, repeatedFirstPlayer)
    }

    func testDifferentSeedsProduceDifferentShuffles() {
        var firstRandom = SeededRandomSource(seed: 1)
        var secondRandom = SeededRandomSource(seed: 2)
        var firstDeck = Array(0..<60)
        var secondDeck = Array(0..<60)

        firstRandom.shuffle(&firstDeck)
        secondRandom.shuffle(&secondDeck)

        XCTAssertNotEqual(firstDeck, secondDeck)
    }

    func testFixedFirstPlayerDoesNotConsumeRandomness() throws {
        let players = (0..<2).map { PlayerID("player-\($0)") }
        let configuration = try GameConfiguration(
            playerIDs: players,
            seed: 42,
            firstPlayer: .fixed(players[1])
        )
        var random = SeededRandomSource(seed: configuration.seed)
        var expectedRandom = SeededRandomSource(seed: configuration.seed)

        XCTAssertEqual(random.firstPlayer(in: configuration), players[1])
        XCTAssertEqual(random.next(), expectedRandom.next())
    }

    func testCodableRestoresGeneratorState() throws {
        var random = SeededRandomSource(seed: 42)
        _ = random.next()
        let data = try JSONEncoder().encode(random)
        var restored = try JSONDecoder().decode(SeededRandomSource.self, from: data)

        XCTAssertEqual(restored, random)
        XCTAssertEqual(restored.next(), random.next())
    }

    func testShuffleHandlesZeroOrOneElementWithoutConsumingRandomness() {
        var random = SeededRandomSource(seed: 42)
        var expectedRandom = SeededRandomSource(seed: 42)
        var empty: [Int] = []
        var single = [1]

        random.shuffle(&empty)
        random.shuffle(&single)

        XCTAssertEqual(empty, [])
        XCTAssertEqual(single, [1])
        XCTAssertEqual(random.next(), expectedRandom.next())
    }
}
