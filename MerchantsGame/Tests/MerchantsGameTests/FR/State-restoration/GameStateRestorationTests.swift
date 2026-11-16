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
            expectFieldError(try encodedData(missing), key: key, kind: .missing)
            var null = original
            null[key] = NSNull()
            expectFieldError(try encodedData(null), key: key, kind: .null)
            var wrongType = original
            wrongType[key] = "not a valid value"
            expectFieldError(try encodedData(wrongType), key: key, kind: .wrongType)
        }
    }

    @Test func optionalTurnIsAbsentDuringDraftButRequiredAfterDraft() throws {
        let configuration = try GameConfiguration(playerIDs: players, seed: 42)
        let draft = try GameState(configuration: configuration)
        var object = try encodedObject(draft)
        object.removeValue(forKey: "turn")
        #expect(try JSONDecoder().decode(GameState.self, from: encodedData(object)) == draft)
        object["turn"] = NSNull()
        #expect(try JSONDecoder().decode(GameState.self, from: encodedData(object)) == draft)
        object["turn"] = "invalid"
        expectFieldError(try encodedData(object), key: "turn", kind: .wrongType)

        var startedObject = try encodedObject(started())
        startedObject.removeValue(forKey: "turn")
        expectDecodeError(try encodedData(startedObject), .invalidTurnState)
    }

    @Test func restoreReportsMalformedDataAndPreservesCause() throws {
        let state = try started()
        let original = try encodedObject(state)
        var missing = original
        missing.removeValue(forKey: "deck")
        var null = original
        null["deck"] = NSNull()
        var wrongType = original
        wrongType["deck"] = "invalid"
        var invalidSeat = original
        var turn = try #require(invalidSeat["turn"] as? [String: Any])
        turn["currentSeat"] = -1
        invalidSeat["turn"] = turn

        for object in [missing, null, wrongType, invalidSeat] {
            do {
                _ = try GameState.restore(from: encodedData(object))
                Issue.record("Expected malformed game data.")
            } catch let error as GameRestorationError {
                #expect(error.localizedDescription == "Game error - corrupted data")
                #expect(error.underlyingError is DecodingError || error.underlyingError is TurnFlowError)
            }
        }
        var corrupted = state
        _ = try corrupted.supply.take(.tea)
        do {
            let data = try JSONEncoder().encode(corrupted)
            _ = try GameState.restore(from: data)
            Issue.record("Expected an invalid game state.")
        } catch let error as GameRestorationError {
            #expect(error.localizedDescription == "Game error - corrupted data")
            #expect(error.underlyingError as? GameStateError == .cubeCountMismatch)
        }
        do {
            _ = try GameState.restore(from: Data("{".utf8))
            Issue.record("Expected malformed JSON.")
        } catch {
            #expect(error.localizedDescription == "Game error - corrupted data")
            #expect(error.underlyingError is DecodingError)
        }
        #expect(try GameState.restore(from: JSONEncoder().encode(state)) == state)
    }

    @Test func rejectsInvalidNestedOwnerValues() throws {
        let original = try encodedObject(started())

        var duplicatePlayers = original
        var configuration = try #require(duplicatePlayers["configuration"] as? [String: Any])
        configuration["playerIDs"] = ["first", "first"]
        duplicatePlayers["configuration"] = configuration
        #expect(throws: GameSetupError.duplicatePlayerID) {
            try JSONDecoder().decode(GameState.self, from: encodedData(duplicatePlayers))
        }

        var invalidSupply = original
        var supply = try #require(invalidSupply["supply"] as? [String: Any])
        supply["tea"] = 6
        invalidSupply["supply"] = supply
        #expect(throws: CubeSupplyError.invalidCount(good: .tea, count: 6)) {
            try JSONDecoder().decode(GameState.self, from: encodedData(invalidSupply))
        }

        var invalidDraft = original
        var draft = try #require(invalidDraft["draft"] as? [String: Any])
        draft["picksMade"] = Int.max
        invalidDraft["draft"] = draft
        #expect(throws: CubeDraftError.invalidState) {
            try JSONDecoder().decode(GameState.self, from: encodedData(invalidDraft))
        }

        var invalidTurn = original
        var turn = try #require(invalidTurn["turn"] as? [String: Any])
        turn["currentSeat"] = -1
        invalidTurn["turn"] = turn
        #expect(throws: TurnFlowError.invalidProgress) {
            try JSONDecoder().decode(GameState.self, from: encodedData(invalidTurn))
        }
    }

    @Test func rejectsFinishedFinalRoundWithWrongTurnSeat() throws {
        var state = try started()
        var actions = 0
        while state.ending.status != .finished && actions < 500 {
            let seat = try #require(state.turn?.currentSeat)
            let player = players[seat]
            let legal = try state.legalActions(for: player)
            let action: GameAction
            if legal.contains(.passPlanning) {
                action = .passPlanning
            } else if legal.contains(.drawCards) {
                action = .drawCards
            } else if legal.contains(.skipTrading) {
                action = .skipTrading
            } else {
                action = try #require(legal.first { if case .deliverCards = $0 { return true }; return false })
            }
            (state, _) = try GameEngine.apply(action, by: player, to: state)
            actions += 1
        }
        #expect(state.ending.status == .finished)
        #expect(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state)) == state)
        var object = try encodedObject(state)
        var turn = try #require(object["turn"] as? [String: Any])
        turn["currentSeat"] = (state.draft.order.first + 1) % players.count
        object["turn"] = turn
        expectDecodeError(try encodedData(object), .invalidTurnState)
    }

    private enum FieldErrorKind { case missing, null, wrongType }

    private func expectFieldError(_ data: Data, key: String, kind: FieldErrorKind) {
        do {
            _ = try JSONDecoder().decode(GameState.self, from: data)
            Issue.record("Expected \(kind) decoding error for \(key).")
        } catch DecodingError.keyNotFound(let missing, let context) where kind == .missing {
            #expect(missing.stringValue == key)
            #expect(context.codingPath.isEmpty)
        } catch DecodingError.valueNotFound(_, let context) where kind == .null {
            #expect(context.codingPath.map(\.stringValue) == [key])
        } catch DecodingError.typeMismatch(_, let context) where kind == .wrongType {
            #expect(context.codingPath.map(\.stringValue) == [key])
        } catch {
            Issue.record("Expected \(kind) decoding error for \(key), received \(error).")
        }
        do {
            _ = try GameState.restore(from: data)
            Issue.record("Expected corrupted data for \(key).")
        } catch {
            #expect(error.localizedDescription == "Game error - corrupted data")
            #expect(error.underlyingError is DecodingError)
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
