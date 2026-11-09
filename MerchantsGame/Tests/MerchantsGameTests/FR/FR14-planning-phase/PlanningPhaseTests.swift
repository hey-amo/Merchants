import XCTest
@testable import MerchantsGame

final class PlanningPhaseTests: XCTestCase {
    private let players = [PlayerID("a"), PlayerID("b")]

    private func state(balance: Int = 100, cranes: Int = 0) throws -> PlanningState {
        let rules = GameRules.standard
        var turn = TurnFlow(order: try SeatOrder(count: 2, first: 0))
        try turn.start()
        var supply = CubeSupply()
        var fleet = Fleet()
        try fleet.load(supply.take(.tea), onto: 0)
        try fleet.load(supply.take(.sugar), onto: 1)
        var tableau = Tableau()
        var stock = try SpecialCardStock(playerCount: 2, catalog: rules.specialCardCatalog)
        for _ in 0..<cranes { try stock.purchase(.crane, for: &tableau) }
        return try PlanningState(
            players: players, rules: rules, turn: turn,
            bank: Bank(restoring: [players[0]: balance, players[1]: 0]),
            supply: supply, fleets: [fleet, Fleet()], stock: stock,
            tableaus: [tableau, Tableau()]
        )
    }

    func testEveryCardExactPriceAndInsufficientFundsAreAtomic() throws {
        for kind in SpecialCardKind.allCases {
            let price = GameRules.standard.specialCardCatalog.entry(for: kind).price
            let goods: [GoodType] = kind == .ship ? [.silk] : kind == .largeShip ? [.silk, .silk] : []
            let before = try state(balance: price - 1)
            XCTAssertThrowsError(try PlanningPhaseRules.apply(.buy(kind, loadCubes: goods), by: players[0], to: before)) {
                guard case .banking = $0 as? PlanningError else { return XCTFail("Expected banking error: \($0)") }
            }
            XCTAssertEqual(try before.bank.balance(of: players[0]).available, price - 1)
            let result = try PlanningPhaseRules.apply(.buy(kind, loadCubes: goods), by: players[0], to: state(balance: price))
            XCTAssertEqual(try result.bank.balance(of: players[0]).available, 0)
            XCTAssertEqual(result.tableaus[0].count(of: kind), 1)
            XCTAssertEqual(result.stock.available(of: kind), before.stock.available(of: kind) - 1)
            if kind == .ship || kind == .largeShip {
                XCTAssertEqual(result.fleets[0].ships.last?.cubes.count, goods.count)
            }
        }
    }

    func testPassAndNonCranePurchaseEndPlanning() throws {
        let initial = try state(cranes: 1)
        for action in [PlanningAction.pass, .buy(.office, loadCubes: [])] {
            let result = try PlanningPhaseRules.apply(action, by: players[0], to: initial)
            XCTAssertEqual(result.turn.status, .active(.trading))
            XCTAssertThrowsError(try PlanningPhaseRules.apply(.exchange(ship: 0, cubeIndex: 0, good: .silk), by: players[0], to: result)) {
                XCTAssertEqual($0 as? PlanningError, .turn(.wrongPhase))
            }
        }
    }

    func testExchangeCranesAndAutomaticEndWhenNoShipsRemain() throws {
        let initial = try state(cranes: 2)
        let one = try PlanningPhaseRules.apply(.exchange(ship: 0, cubeIndex: 0, good: .silk), by: players[0], to: initial)
        XCTAssertEqual(one.supply.available(of: .tea), initial.supply.available(of: .tea) + 1)
        XCTAssertThrowsError(try PlanningPhaseRules.apply(.exchange(ship: 0, cubeIndex: 0, good: .spices), by: players[0], to: one)) {
            XCTAssertEqual($0 as? PlanningError, .turn(.shipAlreadyExchangedThisPhase))
        }
        let two = try PlanningPhaseRules.apply(.exchange(ship: 1, cubeIndex: 0, good: .spices), by: players[0], to: one)
        XCTAssertEqual(two.turn.status, .active(.trading))
    }

    func testCranePurchaseGrantsOnlyOneOptionalExchange() throws {
        let initial = try state(cranes: 1)
        let bought = try PlanningPhaseRules.apply(.buy(.crane, loadCubes: []), by: players[0], to: initial)
        let ended = try PlanningPhaseRules.apply(.endPlanning, by: players[0], to: bought)
        XCTAssertEqual(ended.turn.status, .active(.trading))
        let exchanged = try PlanningPhaseRules.apply(.exchange(ship: 0, cubeIndex: 0, good: .silk), by: players[0], to: bought)
        XCTAssertEqual(exchanged.turn.status, .active(.trading))
    }

    func testExchangeFailuresAndWrongPlayerAreAtomic() throws {
        let original = try state(cranes: 1)
        let cases: [(PlanningAction, PlanningError)] = [
            (.exchange(ship: 0, cubeIndex: 0, good: .tea), .ship(.sameGood)),
            (.exchange(ship: 99, cubeIndex: 0, good: .silk), .ship(.shipNotFound)),
            (.exchange(ship: 0, cubeIndex: 2, good: .silk), .ship(.cubeIndexOutOfRange))
        ]
        for (action, expected) in cases {
            XCTAssertThrowsError(try PlanningPhaseRules.apply(action, by: players[0], to: original)) {
                XCTAssertEqual($0 as? PlanningError, expected)
            }
        }
        XCTAssertThrowsError(try PlanningPhaseRules.apply(.pass, by: players[1], to: original)) {
            XCTAssertEqual($0 as? PlanningError, .turn(.notYourTurn))
        }
        XCTAssertEqual(original.fleets[0].ships[0].cubes[0].good, .tea)
    }

    func testShipPurchasesRejectUnavailableCubesAndWrongLoadCount() throws {
        var initial = try state()
        for _ in 0..<4 { _ = try initial.supply.take(.tea) }
        XCTAssertThrowsError(try PlanningPhaseRules.apply(.buy(.ship, loadCubes: [.tea]), by: players[0], to: initial)) {
            XCTAssertEqual($0 as? PlanningError, .supply(.noneAvailable(.tea)))
        }
        XCTAssertThrowsError(try PlanningPhaseRules.apply(.buy(.largeShip, loadCubes: [.silk]), by: players[0], to: initial)) {
            XCTAssertEqual($0 as? PlanningError, .invalidShipLoad)
        }
        for _ in 0..<4 { _ = try initial.supply.take(.silk) }
        XCTAssertThrowsError(try PlanningPhaseRules.apply(.buy(.largeShip, loadCubes: [.silk, .silk]), by: players[0], to: initial)) {
            XCTAssertEqual($0 as? PlanningError, .supply(.noneAvailable(.silk)))
        }
        XCTAssertEqual(try initial.bank.balance(of: players[0]).available, 100)
        XCTAssertEqual(initial.fleets[0].ships.count, 2)
    }

    func testOwnershipLimitsAndCustomsHouseEffect() throws {
        for kind in [SpecialCardKind.customsHouse, .largeShip] {
            var initial = try state()
            try initial.stock.purchase(kind, for: &initial.tableaus[0])
            let goods: [GoodType] = kind == .largeShip ? [.silk, .tea] : []
            XCTAssertThrowsError(try PlanningPhaseRules.apply(.buy(kind, loadCubes: goods), by: players[0], to: initial)) {
                XCTAssertEqual($0 as? PlanningError, .specialCard(.ownershipLimitReached(kind)))
            }
            XCTAssertEqual(try initial.bank.balance(of: players[0]).available, 100)
        }
        let bought = try PlanningPhaseRules.apply(.buy(.customsHouse, loadCubes: []), by: players[0], to: state())
        XCTAssertEqual(SpecialCardEffects(tableau: bought.tableaus[0], rules: bought.rules).handLimitBonus, 2)
    }

    func testOutOfStockAndUnavailableExchangePreserveOriginalState() throws {
        var initial = try state()
        try initial.stock.purchase(.office, for: &initial.tableaus[1])
        try initial.stock.purchase(.office, for: &initial.tableaus[1])
        for _ in 0..<5 { _ = try initial.supply.take(.silk) }
        let snapshot = initial
        XCTAssertThrowsError(try PlanningPhaseRules.apply(.buy(.office, loadCubes: []), by: players[0], to: initial)) {
            XCTAssertEqual($0 as? PlanningError, .specialCard(.outOfStock(.office)))
        }
        XCTAssertThrowsError(try PlanningPhaseRules.apply(.exchange(ship: 0, cubeIndex: 0, good: .silk), by: players[0], to: initial)) {
            XCTAssertEqual($0 as? PlanningError, .supply(.noneAvailable(.silk)))
        }
        XCTAssertEqual(initial, snapshot)
    }

    func testLargeShipExchangeChoosesCubeSlotAndConservesSupply() throws {
        var initial = try state(cranes: 1)
        initial.fleets[0].addShip(kind: .large)
        try initial.fleets[0].load(initial.supply.take(.indigo), onto: 2)
        try initial.fleets[0].load(initial.supply.take(.lumber), onto: 2)
        let result = try PlanningPhaseRules.apply(
            .exchange(ship: 2, cubeIndex: 1, good: .silk), by: players[0], to: initial
        )
        XCTAssertEqual(result.fleets[0].ships[2].cubes.map(\.good), [.indigo, .silk])
        XCTAssertEqual(result.supply.available(of: .lumber), initial.supply.available(of: .lumber) + 1)
        XCTAssertEqual(result.supply.available(of: .silk), initial.supply.available(of: .silk) - 1)
    }

    func testNoPossibleExtraExchangeAutomaticallyEndsPlanning() throws {
        var initial = try state(cranes: 2)
        for good in GoodType.allCases where good != .tea && good != .sugar {
            while initial.supply.available(of: good) > 0 { _ = try initial.supply.take(good) }
        }
        for _ in 0..<4 { _ = try initial.supply.take(.tea) }
        let result = try PlanningPhaseRules.apply(
            .exchange(ship: 0, cubeIndex: 0, good: .sugar), by: players[0], to: initial
        )
        // The returned tea makes an exchange on the second ship possible.
        guard case .active(.planning) = result.turn.status else { return XCTFail("Expected optional exchange") }
        let completed = try PlanningPhaseRules.apply(
            .exchange(ship: 1, cubeIndex: 0, good: .tea), by: players[0], to: result
        )
        XCTAssertEqual(completed.turn.status, .active(.trading))
    }

    func testInvalidParticipantsAndInvalidLoadsAreRejected() throws {
        let initial = try state()
        XCTAssertThrowsError(try PlanningPhaseRules.apply(.pass, by: PlayerID("unknown"), to: initial)) {
            XCTAssertEqual($0 as? PlanningError, .unknownPlayer)
        }
        XCTAssertThrowsError(try PlanningPhaseRules.apply(.buy(.office, loadCubes: [.tea]), by: players[0], to: initial)) {
            XCTAssertEqual($0 as? PlanningError, .invalidShipLoad)
        }
        var invalid = initial
        invalid.fleets.removeLast()
        XCTAssertThrowsError(try PlanningPhaseRules.apply(.pass, by: players[0], to: invalid)) {
            XCTAssertEqual($0 as? PlanningError, .invalidState)
        }
    }

    func testNewlyBoughtShipCannotBeExchangedAndExtraIsNotGranted() throws {
        let bought = try PlanningPhaseRules.apply(.buy(.ship, loadCubes: [.silk]), by: players[0], to: state(cranes: 1))
        XCTAssertEqual(bought.turn.status, .active(.trading))
        XCTAssertThrowsError(try PlanningPhaseRules.apply(
            .exchange(ship: 2, cubeIndex: 0, good: .tea), by: players[0], to: bought
        )) {
            XCTAssertEqual($0 as? PlanningError, .turn(.wrongPhase))
        }
    }

    func testSameGoodRejectedEvenWhenSupplyOfThatGoodIsEmpty() throws {
        var initial = try state()
        while initial.supply.available(of: .tea) > 0 { _ = try initial.supply.take(.tea) }
        XCTAssertThrowsError(try PlanningPhaseRules.apply(
            .exchange(ship: 0, cubeIndex: 0, good: .tea), by: players[0], to: initial
        )) {
            XCTAssertEqual($0 as? PlanningError, .ship(.sameGood))
        }
    }
}
