import XCTest
@testable import MerchantsGame

final class GameSetupTests: XCTestCase {
    func testSetupInitializesAllOwnersForEveryPlayerCount() throws {
        for count in 2...4 {
            let players = (0..<count).map { PlayerID("player-\($0)") }
            let configuration = try GameConfiguration(playerIDs: players, seed: 9, firstPlayer: .fixed(players[1]))
            let setup = try GameSetup(configuration: configuration)
            XCTAssertEqual(setup.deck.remaining, 60 - count * 3 - 6)
            XCTAssertEqual(setup.hands.map(\.count), Array(repeating: 3, count: count))
            XCTAssertEqual(setup.marketplace.visibleCards.count, 6)
            XCTAssertEqual(setup.draft.order.first, 1)
            XCTAssertEqual(setup.draft.fleets.count, count)
            XCTAssertEqual(setup.tableaus.count, count)
            for player in players {
                XCTAssertEqual(try setup.bank.balance(of: player).available, 0)
            }
            for good in GoodType.allCases {
                XCTAssertEqual(setup.draft.supply.available(of: good), CubeSupply.cubesPerGood)
            }
            for kind in SpecialCardKind.allCases {
                XCTAssertEqual(setup.specialCardStock.available(of: kind),
                               try configuration.rules.specialCardCatalog.stock(for: kind, playerCount: count))
            }
        }
    }

    func testSameSeedReproducesSetupAndDifferentSeedChangesDeck() throws {
        let players = [PlayerID("a"), PlayerID("b")]
        let configuration = try GameConfiguration(playerIDs: players, seed: 10)
        let first = try GameSetup(configuration: configuration)
        let repeated = try GameSetup(configuration: configuration)
        let different = try GameSetup(configuration: GameConfiguration(playerIDs: players, seed: 11))
        XCTAssertEqual(first, repeated)
        XCTAssertNotEqual(first.deck, different.deck)
    }

    func testFixedFirstPlayerDoesNotConsumeRandomnessAfterShuffle() throws {
        let players = [PlayerID("a"), PlayerID("b")]
        let configuration = try GameConfiguration(playerIDs: players, seed: 42, firstPlayer: .fixed(players[1]))
        let setup = try GameSetup(configuration: configuration)
        var random = SeededRandomSource(seed: configuration.seed)
        _ = DeckBuilder.standardDeck(using: &random)
        XCTAssertEqual(setup.random, random)
    }
}
