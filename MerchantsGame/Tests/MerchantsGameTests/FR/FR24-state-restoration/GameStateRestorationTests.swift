import Foundation
import Testing
@testable import MerchantsGame

@Suite("FR24 state restoration")
struct GameStateRestorationTests {
    private let players = [PlayerID("first"), PlayerID("second")]

    private func started() throws -> GameState {
        let configuration = try GameConfiguration(
            playerIDs: players,
            seed: 42,
            firstPlayer: .fixed(players[0])
        )
        var state = try GameState(configuration: configuration)
        for (seat, ship, good) in [(1, 0, GoodType.tea), (0, 0, .sugar), (0, 1, .tea), (1, 1, .sugar)] {
            (state, _) = try GameEngine.apply(
                .draftCube(good: good, ship: ship),
                by: players[seat],
                to: state
            )
        }
        return state
    }

    @Test func roundTripsMidGameAndContinuesDeterministically() throws {
        var original = try started()
        (original, _) = try GameEngine.apply(.passPlanning, by: players[0], to: original)
        (original, _) = try GameEngine.apply(.drawCards, by: players[0], to: original)

        let restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(original))
        #expect(restored == original)

        let action: GameAction = .passPlanning
        let player = players[try #require(restored.turn?.currentSeat)]
        let (originalNext, originalEvents) = try GameEngine.apply(action, by: player, to: original)
        let (restoredNext, restoredEvents) = try GameEngine.apply(action, by: player, to: restored)
        #expect(restoredNext == originalNext)
        #expect(restoredEvents == originalEvents)
    }

    @Test func rejectsShipOverCapacityWithExactError() throws {
        let state = try started()
        var object = try encodedObject(state)
        var fleets = try #require(object["fleets"] as? [[String: Any]])
        var fleet = try #require(fleets.first)
        var ships = try #require(fleet["ships"] as? [[String: Any]])
        var ship = try #require(ships.first)
        var cubes = try #require(ship["cubes"] as? [[String: Any]])
        cubes.append(try #require(cubes.first))
        ship["cubes"] = cubes
        ships[0] = ship
        fleet["ships"] = ships
        fleets[0] = fleet
        object["fleets"] = fleets

        expectDecodeError(try encodedData(object), .shipOverCapacity)
    }

    @Test func rejectsOverCapacityShipInsideDraftWithExactError() throws {
        let state = try started()
        var object = try encodedObject(state)
        var draft = try #require(object["draft"] as? [String: Any])
        var fleets = try #require(draft["fleets"] as? [[String: Any]])
        var fleet = try #require(fleets.first)
        var ships = try #require(fleet["ships"] as? [[String: Any]])
        var ship = try #require(ships.first)
        var cubes = try #require(ship["cubes"] as? [[String: Any]])
        cubes.append(try #require(cubes.first))
        ship["cubes"] = cubes
        ships[0] = ship
        fleet["ships"] = ships
        fleets[0] = fleet
        draft["fleets"] = fleets
        object["draft"] = draft

        expectDecodeError(try encodedData(object), .shipOverCapacity)
    }

    @Test func rejectsSixtyOneCardsWithExactError() throws {
        let state = try started()
        var object = try encodedObject(state)
        var deck = try #require(object["deck"] as? [String: Any])
        var cards = try #require(deck["cards"] as? [[String: Any]])
        cards.append(try #require(cards.first))
        deck["cards"] = cards
        object["deck"] = deck

        expectDecodeError(try encodedData(object), .cardCountMismatch)
    }

    @Test func rejectsIncorrectGoodsDistributionEvenWhenTotalIsSixty() throws {
        var state = try started()
        var deck = state.deck
        var cards = try deck.draw(deck.remaining)
        let first = try #require(cards.first)
        let replacement = try #require(cards.first(where: { $0.good != first.good }))
        cards[0] = replacement
        state.deck = DrawDeck(cards: cards)
        expectDecodeError(try JSONEncoder().encode(state), .cardCountMismatch)
    }

    @Test func rejectsCoinsDuringDraft() throws {
        let configuration = try GameConfiguration(playerIDs: players, seed: 42)
        var state = try GameState(configuration: configuration)
        state.bank = try Bank(restoring: [players[0]: 1, players[1]: 0])
        expectDecodeError(try JSONEncoder().encode(state), .invalidTurnState)
    }

    @Test func rejectsCubeCountMismatchWithExactError() throws {
        var state = try started()
        _ = try state.supply.take(.tea)

        expectDecodeError(try JSONEncoder().encode(state), .cubeCountMismatch)
    }

    @Test func rejectsHandOverLimitWithExactError() throws {
        let state = try started()
        var object = try encodedObject(state)
        var deck = try #require(object["deck"] as? [String: Any])
        var deckCards = try #require(deck["cards"] as? [[String: Any]])
        let movedCards = Array(deckCards.suffix(4))
        deckCards.removeLast(4)
        deck["cards"] = deckCards
        object["deck"] = deck

        var hands = try #require(object["hands"] as? [[String: Any]])
        var hand = try #require(hands.first)
        var cards = try #require(hand["cards"] as? [[String: Any]])
        cards.append(contentsOf: movedCards)
        hand["cards"] = cards
        hands[0] = hand
        object["hands"] = hands

        expectDecodeError(try encodedData(object), .handOverLimit)
    }

    @Test func rejectsNegativeBalanceWithExactError() throws {
        let object = try encodedObject(try started())
        var changed = false
        let bank = try #require(object["bank"])
        var corrupted = object
        corrupted["bank"] = replacingAvailableBalance(in: bank, changed: &changed)
        #expect(changed)

        expectDecodeError(try encodedData(corrupted), .negativeBalance)
    }

    @Test func rejectsSpecialCardStockMismatchWithExactError() throws {
        var state = try started()
        var stock = state.stock
        var unrelatedTableau = Tableau()
        try stock.purchase(.ship, for: &unrelatedTableau)
        state.stock = stock

        expectDecodeError(try JSONEncoder().encode(state), .invalidSpecialCardStock)
    }

    @Test func rejectsMismatchBetweenDraftAndTurnState() throws {
        var object = try encodedObject(try started())
        object["turn"] = NSNull()

        expectDecodeError(try encodedData(object), .invalidTurnState)
    }

    @Test func rejectsFinalRoundBeforeDeckIsEmpty() throws {
        var state = try started()
        try state.ending.deckEmptied(by: 0)
        expectDecodeError(try JSONEncoder().encode(state), .invalidTurnState)
    }

    @Test func rejectsMissingPurchasedShip() throws {
        var state = try started()
        try state.stock.purchase(.ship, for: &state.tableaux[0])
        expectDecodeError(try JSONEncoder().encode(state), .invalidFleet)
    }

    @Test func rejectsHugeTableauCountsWithoutOverflow() throws {
        var state = try started()
        try state.stock.purchase(.ship, for: &state.tableaux[0])
        var object = try encodedObject(state)
        var tableaux = try #require(object["tableaux"] as? [[String: Any]])
        var tableau = tableaux[0]
        var counts = try #require(tableau["counts"] as? [Any])
        try #require(counts.count == 2)
        counts[1] = NSNumber(value: Int.max)
        tableau["counts"] = counts
        tableaux[0] = tableau
        tableaux[1] = tableau
        object["tableaux"] = tableaux

        expectDecodeError(try encodedData(object), .invalidSpecialCardStock)
    }

    @Test func rejectsOutOfSyncDraftSnapshotDuringDrafting() throws {
        let configuration = try GameConfiguration(
            playerIDs: players,
            seed: 42,
            firstPlayer: .fixed(players[0])
        )
        var state = try GameState(configuration: configuration)
        (state, _) = try GameEngine.apply(
            .draftCube(good: .tea, ship: 0),
            by: players[1],
            to: state
        )
        var fleets = state.fleets
        var supply = state.supply
        try fleets[0].load(supply.take(.sugar), onto: 0)
        state.fleets = fleets
        state.supply = supply

        expectDecodeError(try JSONEncoder().encode(state), .invalidTurnState)
    }

    @Test func rejectsCardsMovedToMarketplaceDuringDraft() throws {
        let configuration = try GameConfiguration(playerIDs: players, seed: 42)
        var object = try encodedObject(GameState(configuration: configuration))
        var deck = try #require(object["deck"] as? [String: Any])
        var cards = try #require(deck["cards"] as? [[String: Any]])
        let last = cards.popLast()
        let moved = try #require(last)
        deck["cards"] = cards
        object["deck"] = deck
        var marketplace = try #require(object["marketplace"] as? [String: Any])
        var stacks = try #require(marketplace["stacks"] as? [[[String: Any]]])
        stacks[0].append(moved)
        marketplace["stacks"] = stacks
        object["marketplace"] = marketplace

        expectDecodeError(try encodedData(object), .invalidTurnState)
    }

    @Test func rejectsExchangeProgressWithoutMatchingCranes() throws {
        var state = try started()
        let unpurchasedStock = state.stock
        let unpurchasedTableau = state.tableaux[0]
        try state.stock.purchase(.crane, for: &state.tableaux[0])
        (state, _) = try GameEngine.apply(
            .exchangeCube(ship: 0, cubeIndex: 0, good: .silk), by: players[0], to: state
        )
        #expect(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state)) == state)
        state.stock = unpurchasedStock
        state.tableaux[0] = unpurchasedTableau
        expectDecodeError(try JSONEncoder().encode(state), .invalidTurnState)
    }

    @Test func rejectsCranePurchaseProgressWithoutOwnedCrane() throws {
        var state = try started()
        state.bank = try Bank(restoring: [players[0]: 12, players[1]: 0])
        let unpurchasedStock = state.stock
        let unpurchasedTableau = state.tableaux[0]
        (state, _) = try GameEngine.apply(.buySpecialCard(kind: .crane, loadCubes: []), by: players[0], to: state)
        #expect(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state)) == state)
        state.stock = unpurchasedStock
        state.tableaux[0] = unpurchasedTableau
        expectDecodeError(try JSONEncoder().encode(state), .invalidTurnState)
    }

    @Test func rejectsMissingNullAndWrongTypedRequiredStateFields() throws {
        let original = try encodedObject(started())
        let required = ["configuration", "random", "deck", "hands", "marketplace",
                        "bank", "stock", "tableaux", "draft", "ending", "fleets", "supply"]
        for key in required {
            var missing = original
            missing.removeValue(forKey: key)
            #expect(throws: DecodingError.self, "Missing \(key)") {
                try JSONDecoder().decode(GameState.self, from: encodedData(missing))
            }
            var null = original
            null[key] = NSNull()
            #expect(throws: DecodingError.self, "Null \(key)") {
                try JSONDecoder().decode(GameState.self, from: encodedData(null))
            }
            var wrongType = original
            wrongType[key] = "not a valid value"
            #expect(throws: DecodingError.self, "Wrong type for \(key)") {
                try JSONDecoder().decode(GameState.self, from: encodedData(wrongType))
            }
        }
    }

    private func encodedObject(_ state: GameState) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
    }

    private func encodedData(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    private func replacingAvailableBalance(in value: Any, changed: inout Bool) -> Any {
        if let dictionary = value as? [String: Any] {
            var result: [String: Any] = [:]
            for (key, nestedValue) in dictionary {
                if key == "available" {
                    result[key] = -1
                    changed = true
                } else {
                    result[key] = replacingAvailableBalance(in: nestedValue, changed: &changed)
                }
            }
            return result
        }
        if let array = value as? [Any] {
            return array.map { replacingAvailableBalance(in: $0, changed: &changed) }
        }
        return value
    }

    private func expectDecodeError(_ data: Data, _ expected: GameStateError) {
        do {
            _ = try JSONDecoder().decode(GameState.self, from: data)
            Issue.record("Expected state decoding to fail with \(expected).")
        } catch let error as GameStateError {
            #expect(error == expected)
        } catch {
            Issue.record("Expected \(expected), received \(error).")
        }
    }
}
