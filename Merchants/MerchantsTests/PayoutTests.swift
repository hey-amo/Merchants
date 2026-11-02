//
//  PayoutTests.swift
//  MerchantsTests
//

import XCTest
@testable import Merchants

final class PayoutTests: XCTestCase {
    private final class TestPlayer {
        let cubes: [GoodsCube]
        var coins: Int

        init(cubes: [GoodsCube], coins: Int = 0) {
            self.cubes = cubes
            self.coins = coins
        }
    }

    private final class TestGame {
        private(set) var marketplace: [GoodsCube]
        private let players: [TestPlayer]

        init(marketplace: [GoodsCube], players: [TestPlayer]) {
            precondition(marketplace.count == GameConstants.marketplaceSize)
            self.marketplace = marketplace
            self.players = players
        }

        func deliver(_ cards: [GoodsCube], atMarketIndices indices: [Int]) {
            precondition(!cards.isEmpty)
            precondition(cards.allSatisfy { $0 == cards[0] })
            precondition(cards.count == indices.count)
            precondition(Set(indices).count == indices.count)
            precondition(indices.allSatisfy { marketplace.indices.contains($0) })

            for (card, index) in zip(cards, indices) {
                marketplace[index] = card
            }

            for player in players {
                let payout = player.cubes.reduce(into: 0) { total, cube in
                    total += marketplace.filter { $0 == cube }.count
                }
                player.coins += payout
            }
        }
    }

    func testDeliveryTriggersPayoutForEveryPlayer() {
        let firstPlayer = TestPlayer(cubes: [.indigo, .indigo, .tea], coins: 10)
        let secondPlayer = TestPlayer(cubes: [.indigo, .sugar, .sugar, .spices], coins: 20)
        let thirdPlayer = TestPlayer(cubes: [], coins: 30)
        let game = TestGame(
            marketplace: [.tea, .sugar, .indigo, .spices, .silk, .lumber],
            players: [firstPlayer, secondPlayer, thirdPlayer]
        )

        game.deliver([.indigo, .indigo], atMarketIndices: [3, 4])

        XCTAssertEqual(game.marketplace.count, GameConstants.marketplaceSize)
        XCTAssertEqual(game.marketplace.filter { $0 == .indigo }.count, 3)

        // Expect payout of coins based on the number of cubes each player has in the marketplace after delivery.
        XCTAssertEqual(firstPlayer.coins, 17)
        XCTAssertEqual(secondPlayer.coins, 25)
        XCTAssertEqual(thirdPlayer.coins, 30)
    }
}
