public enum GameEvent: Codable, Equatable, Sendable {
    case cubeDrafted(player: PlayerID, good: GoodType, ship: Int)
    case cubeExchanged(player: PlayerID, ship: Int, cubeIndex: Int, good: GoodType)
    case specialCardBought(player: PlayerID, kind: SpecialCardKind, loadCubes: [GoodType])
    case cardsDelivered(player: PlayerID, placements: [DeliveryPlacement])
    case coinsEarned(player: PlayerID, amount: Int, reason: TransactionReason)
    case cardsDrawn(player: PlayerID, count: Int)
    case officeExtrasDrawn(player: PlayerID, count: Int)
    case tradingSkipped(player: PlayerID)
    case turnEnded(player: PlayerID)
    case deckEmptied
    case finalRoundBegan(endsAfter: PlayerID)
    case gameEnded(winners: [PlayerID])
    case planningPassed(player: PlayerID)
    case planningEnded(player: PlayerID)
}
