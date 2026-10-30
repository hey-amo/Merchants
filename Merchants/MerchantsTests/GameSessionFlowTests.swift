import XCTest
@testable import Merchants

@MainActor
final class GameSessionFlowTests: XCTestCase {
    func testCubeDraftUsesSnakeOrderAndGivesEachPlayerTwoCubes() throws {
        let session = makeSession()
        let expectedOrder = [
            session.players[1].playerId,
            session.players[0].playerId,
            session.players[0].playerId,
            session.players[1].playerId
        ]
        var actualOrder: [Int] = []

        while session.stage == .cubeDraft {
            actualOrder.append(try XCTUnwrap(session.activePlayer).playerId)
            let color = try XCTUnwrap(session.game.cubePile.first)
            try session.selectDraftCube(color)
        }

        XCTAssertEqual(actualOrder, expectedOrder)
        XCTAssertEqual(session.players.map(\.cubes.count), [2, 2])
        XCTAssertEqual(session.stage, .phase1)
    }

    func testTurnRequiresPhaseOneThenPhaseTwoThenEndTurn() throws {
        let session = makeSession()
        try finishDraft(session)

        let currentPlayer = try XCTUnwrap(session.activePlayer)
        XCTAssertEqual(currentPlayer.state, .thinking)
        XCTAssertThrowsError(try session.drawTwoCards())
        try session.passPhase1()
        XCTAssertEqual(session.stage, .phase2)
        XCTAssertEqual(currentPlayer.state, .thinking)
        XCTAssertThrowsError(try session.endTurn())

        try session.drawTwoCards()
        XCTAssertTrue(session.phase2ActionCompleted)
        try session.endTurn()

        XCTAssertEqual(session.stage, .phase1)
        XCTAssertFalse(session.phase2ActionCompleted)
        XCTAssertEqual(session.activePlayer?.playerId, session.players[1].playerId)
        XCTAssertEqual(currentPlayer.state, .done)
        XCTAssertEqual(session.activePlayer?.state, .thinking)
    }

    func testDeliveryReplacesUniqueSpacesAndPaysAllMatchingCubes() throws {
        let session = makeSession()
        try finishDraft(session)
        try session.passPhase1()

        let activePlayer = try XCTUnwrap(session.activePlayer)
        let otherPlayer = try XCTUnwrap(session.players.first { $0 !== activePlayer })
        activePlayer.cubes = [.tea]
        otherPlayer.cubes = [.tea]
        activePlayer.hand = [.tea, .tea]
        session.game.marketplace = [.sugar, .indigo, .spices, .silk, .lumber, .sugar]

        try session.deliverGoods(color: .tea, to: [1, 2])

        XCTAssertEqual(session.game.marketplace.filter { $0 == .tea }.count, 2)
        XCTAssertEqual(activePlayer.hand, [])
        XCTAssertEqual(activePlayer.coins, 2)
        XCTAssertEqual(otherPlayer.coins, 2)
        XCTAssertThrowsError(try session.deliverGoods(color: .tea, to: [3]))
    }

    func testDockerGrantsExtraExchangesAfterThePhaseOneAction() throws {
        let session = makeSession()
        try finishDraft(session)

        let activePlayer = try XCTUnwrap(session.activePlayer)
        activePlayer.tableau.append(contentsOf: BuildingDefinition.makeDeck().filter { $0.name == "Docker" })
        try session.passPhase1()

        XCTAssertEqual(session.dockerExchangesRemaining, 2)
        try session.exchangeCube(at: 0, for: nextAvailableColor(in: session, excluding: activePlayer.cubes[0]))
        XCTAssertEqual(session.stage, .phase1)
        XCTAssertEqual(session.dockerExchangesRemaining, 1)

        let excludedColors = Set(activePlayer.cubes)
        let secondExchangeColor = try XCTUnwrap(
            GoodsCube.allCases.first {
                !excludedColors.contains($0) && session.availableCubeCount(for: $0) > 0
            }
        )
        try session.exchangeCube(at: 1, for: secondExchangeColor)

        XCTAssertEqual(session.stage, .phase2)
        XCTAssertEqual(session.dockerExchangesRemaining, 0)
    }

    func testOfficeBonusIsOptionalAndDeckExhaustionEndsTheGame() throws {
        let session = makeSession()
        try finishDraft(session)

        let activePlayer = try XCTUnwrap(session.activePlayer)
        activePlayer.tableau.append(
            try XCTUnwrap(BuildingDefinition.makeDeck().first { $0.name == "Office" })
        )
        activePlayer.hand = [.tea]
        session.game.drawPile = [.silk]
        try session.passPhase1()
        try session.deliverGoods(color: .tea, to: [0])

        XCTAssertTrue(session.officeBonusAvailable)
        XCTAssertThrowsError(try session.endTurn())

        try session.resolveOfficeBonus(drawCard: true)
        XCTAssertEqual(activePlayer.hand, [.silk])
        try session.endTurn()

        XCTAssertEqual(session.stage, .finished)
        XCTAssertEqual(session.game.currentState, .gameOver)
    }

    func testEmptyDrawDeckDoesNotEndGameUntilTheActivePlayerEndsTheirTurn() throws {
        let session = makeSession()
        try finishDraft(session)
        let currentPlayer = try XCTUnwrap(session.activePlayer)
        session.game.drawPile = [.silk]

        try session.passPhase1()
        try session.drawTwoCards()

        XCTAssertTrue(session.game.drawPile.isEmpty)
        XCTAssertEqual(session.stage, .phase2)
        XCTAssertEqual(currentPlayer.state, .thinking)
        XCTAssertTrue(session.phase2ActionCompleted)

        try session.endTurn()

        XCTAssertEqual(session.stage, .finished)
        XCTAssertEqual(session.game.activePlayer?.playerId, currentPlayer.playerId)
        XCTAssertEqual(currentPlayer.state, .done)
    }

    func testGameDefinitionsMatchRulesHandLimitAndSpecialCards() {
        let deck = BuildingDefinition.makeDeck()
        let counts = Dictionary(grouping: deck, by: \.name).mapValues(\.count)

        XCTAssertEqual(GameConstants.maxHandSize, 6)
        XCTAssertEqual(counts["Ship"], 14)
        XCTAssertEqual(counts["Office"], 2)
        XCTAssertEqual(counts["Docker"], 2)
        XCTAssertEqual(counts["Trade agreement"], 2)
        XCTAssertNil(counts["Crane"])
        XCTAssertNil(counts["Warehouse"])
    }

    private func makeSession() -> GameSession {
        GameSession(players: [
            Player(playerId: 1, coins: 0),
            Player(playerId: 2, coins: 0)
        ])
    }

    private func finishDraft(_ session: GameSession) throws {
        while session.stage == .cubeDraft {
            let color = try XCTUnwrap(session.game.cubePile.first)
            try session.selectDraftCube(color)
        }
    }

    private func nextAvailableColor(in session: GameSession, excluding color: GoodsCube) throws -> GoodsCube {
        try XCTUnwrap(
            GoodsCube.allCases.first {
                $0 != color && session.availableCubeCount(for: $0) > 0
            }
        )
    }
}
