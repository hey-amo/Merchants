import XCTest
@testable import Merchants

final class GameWinnerTests: XCTestCase {

    func testWinnerUsesSuppliedPlayersAndSortsByCoins() {
        let players = [
            Player(playerId: 1, coins: 10),
            Player(playerId: 2, coins: 14),
            Player(playerId: 3, coins: 3)
        ]
        let view = WinnerScreenView(players: players)

        XCTAssertEqual(view.sortedPlayers.map(\.playerId), [2, 1, 3])
        XCTAssertEqual(view.winners.map(\.playerId), [2])
    }

    func testWinnerIsATie() {
        let players = [
            Player(playerId: 1, coins: 10),
            Player(playerId: 2, coins: 14),
            Player(playerId: 3, coins: 14)
        ]
        let view = WinnerScreenView(players: players)

        XCTAssertEqual(Set(view.winners.map(\.playerId)), Set([2, 3]))
    }

    func testEmptyPlayerListHasNoWinners() {
        let view = WinnerScreenView(players: [])

        XCTAssertTrue(view.sortedPlayers.isEmpty)
        XCTAssertTrue(view.winners.isEmpty)
    }
}
