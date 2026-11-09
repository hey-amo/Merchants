import Foundation
import Testing
@testable import MerchantsGame

@Suite("Game actions and events")
struct GameActionTests {
    @Test func actionsRoundTrip() throws {
        let placement = DeliveryPlacement(slot: 1, card: GoodsCard(good: .tea))
        let actions: [GameAction] = [
            .draftCube(good: .tea, ship: 0), .exchangeCube(ship: 1, cubeIndex: 0, good: .sugar),
            .buySpecialCard(kind: .largeShip, loadCubes: [.tea, .sugar]), .passPlanning, .endPlanning,
            .deliverCards([placement]), .drawCards, .skipTrading
        ]
        let data = try JSONEncoder().encode(actions)
        #expect(try JSONDecoder().decode([GameAction].self, from: data) == actions)
    }

    @Test func eventsRoundTripWithoutDrawnCardIdentities() throws {
        let p = PlayerID("one")
        let events: [GameEvent] = [
            .cubeDrafted(player: p, good: .tea, ship: 0),
            .cubeExchanged(player: p, ship: 1, cubeIndex: 0, good: .sugar),
            .specialCardBought(player: p, kind: .office, loadCubes: []),
            .cardsDelivered(player: p, placements: [DeliveryPlacement(slot: 0, card: GoodsCard(good: .tea))]),
            .coinsEarned(player: p, amount: 2, reason: .deliveryPayout(.tea)),
            .cardsDrawn(player: p, count: 2), .officeExtrasDrawn(player: p, count: 1),
            .tradingSkipped(player: p), .turnEnded(player: p), .deckEmptied,
            .finalRoundBegan(endsAfter: p), .gameEnded(winners: [p]),
            .planningPassed(player: p), .planningEnded(player: p)
        ]
        #expect(try JSONDecoder().decode([GameEvent].self, from: JSONEncoder().encode(events)) == events)
        let encodedDraw = String(decoding: try JSONEncoder().encode(GameEvent.cardsDrawn(player: p, count: 2)), as: UTF8.self)
        #expect(!encodedDraw.contains("good"))
    }
}
