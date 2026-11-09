import Foundation
import Testing
@testable import MerchantsGame

@Suite("End game and winners")
struct GameEndingTests {
    @Test(arguments: [EndGameRule.immediate, .oneMoreTurn])
    func triggerCanFollowBaseDrawOrOfficeDraw(rule: EndGameRule) throws {
        for (deckSize, baseCount) in [(1, 1), (2, 2), (3, 2)] {
            var deck = DrawDeck(cards: Array(repeating: GoodsCard(good: .tea), count: deckSize))
            let base = try deck.draw(baseCount)
            #expect(base.count == baseCount)
            if !deck.isEmpty {
                let office = try deck.draw(1)
                #expect(office.count == 1)
            }
            #expect(deck.isEmpty)
            var ending = GameEnding(rule: rule, order: try SeatOrder(count: 3, first: 0))
            try ending.deckEmptied(by: 1)
            if rule == .immediate {
                #expect(ending.status == .finished)
                #expect(throws: GameEndingError.alreadyEnded) { try ending.requireActive() }
                #expect(throws: GameEndingError.alreadyEnded) { try ending.deckEmptied(by: 1) }
            } else {
                #expect(ending.status == .finalRound(nextSeat: 1))
                #expect(throws: GameEndingError.alreadyTriggered) { try ending.deckEmptied(by: 1) }
            }
        }
    }

    @Test func finalRoundEndsAtLastSeatWithEqualTurnCounts() throws {
        for count in 2...4 {
            for first in 0..<count {
                let order = try SeatOrder(count: count, first: first)
                for emptyingOffset in 0..<count {
                    let emptyingSeat = (first + emptyingOffset) % count
                    var completed = Array(repeating: 3, count: count)
                    for offset in 0..<emptyingOffset {
                        completed[(first + offset) % count] += 1
                    }
                    var ending = GameEnding(rule: .oneMoreTurn, order: order)
                    try ending.deckEmptied(by: emptyingSeat)
                    var seat = emptyingSeat
                    while true {
                        try ending.requireActive()
                        try ending.turnCompleted(by: seat)
                        completed[seat] += 1
                        if seat == order.last {
                            #expect(ending.status == .finished)
                            break
                        }
                        seat = try order.next(after: seat)
                        #expect(ending.status == .finalRound(nextSeat: seat))
                    }
                    #expect(Set(completed).count == 1)
                    #expect(throws: GameEndingError.alreadyEnded) {
                        try ending.turnCompleted(by: order.first)
                    }
                }
            }
        }
    }

    @Test func finalRoundRejectsRepeatedTriggerAndOutOfOrderTurns() throws {
        var ending = GameEnding(rule: .oneMoreTurn, order: try SeatOrder(count: 3, first: 0))
        #expect(throws: GameEndingError.invalidSeat) { try ending.deckEmptied(by: -1) }
        #expect(ending.status == .ongoing)
        try ending.deckEmptied(by: 1)
        #expect(throws: GameEndingError.unexpectedSeat) { try ending.turnCompleted(by: 2) }
        #expect(ending.status == .finalRound(nextSeat: 1))
        try ending.turnCompleted(by: 1)
        #expect(throws: GameEndingError.unexpectedSeat) { try ending.turnCompleted(by: 1) }
        #expect(throws: GameEndingError.invalidSeat) { try ending.turnCompleted(by: 3) }
        try ending.turnCompleted(by: 2)
        #expect(ending.status == .finished)
    }

    @Test(arguments: [
        ([3, 5, 1, 2], [1]),
        ([5, 1, 5, 2], [0, 2]),
        ([5, 5, 5, 5], [0, 1, 2, 3])
    ])
    func standingsUseBalancesAndPreserveSeatOrder(balances: [Int], winningSeats: [Int]) throws {
        let players = (0..<4).map { PlayerID("player\($0)") }
        let bank = try Bank(restoring: Dictionary(uniqueKeysWithValues: zip(players, balances)))
        var ending = GameEnding(rule: .immediate, order: try SeatOrder(count: 4, first: 2))
        #expect(throws: GameEndingError.gameNotOver) {
            try ending.standings(players: players, bank: bank)
        }
        try ending.deckEmptied(by: 2)
        let standings = try ending.standings(players: players, bank: bank)
        #expect(standings.entries.map(\.player) == players)
        #expect(standings.entries.map(\.balance.available) == balances)
        #expect(standings.winners == winningSeats.map { players[$0] })
        #expect(throws: GameEndingError.invalidPlayers) {
            try ending.standings(players: [players[0], players[0], players[2], players[3]], bank: bank)
        }
        #expect(throws: GameEndingError.invalidPlayers) {
            try ending.standings(players: Array(players.prefix(3)), bank: bank)
        }
        let incompleteBank = try Bank(playerIDs: Array(players.prefix(3)))
        #expect(throws: GameEndingError.invalidPlayers) {
            try ending.standings(players: players, bank: incompleteBank)
        }
    }

    @Test func rulesAndEndingRoundTripAndLegacyRulesDefault() throws {
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        #expect(GameRules.standard.endGameRule == .oneMoreTurn)
        #expect(try decoder.decode(GameRules.self, from: Data("{}".utf8)).endGameRule == .oneMoreTurn)
        let immediate = try GameRules(specialCardCatalog: .standard, endGameRule: .immediate)
        #expect(try decoder.decode(GameRules.self, from: encoder.encode(immediate)) == immediate)
        var ending = GameEnding(rule: .oneMoreTurn, order: try SeatOrder(count: 3, first: 1))
        try ending.deckEmptied(by: 1)
        try ending.turnCompleted(by: 1)
        let restored = try decoder.decode(GameEnding.self, from: encoder.encode(ending))
        #expect(restored == ending)
        var continued = restored
        try continued.turnCompleted(by: 2)
        try continued.turnCompleted(by: 0)
        #expect(continued.status == .finished)
    }

    @Test func invalidRestoredFinalRoundIsRejected() throws {
        let ending = GameEnding(rule: .immediate, order: try SeatOrder(count: 2, first: 0))
        let encoded = try JSONEncoder().encode(ending)
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object["status"] = ["finalRound": ["nextSeat": 0]]
        let invalid = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(GameEnding.self, from: invalid)
        }
        object["rule"] = ["oneMoreTurn": [:]]
        object["status"] = ["finalRound": ["nextSeat": 2]]
        let invalidSeat = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(GameEnding.self, from: invalidSeat)
        }
    }
}
