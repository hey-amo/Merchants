public struct DeliveryPlacement: Codable, Equatable, Sendable {
    public enum Source: Codable, Equatable, Sendable {
        case hand(GoodType)
    }

    public let slot: Int
    public let card: GoodsCard

    /// Deliveries currently always come from the hand. The stored card retains the existing Codable format.
    public var source: Source { .hand(card.good) }

    public init(slot: Int, card: GoodsCard) {
        self.slot = slot
        self.card = card
    }

    public init(slot: Int, source: Source) {
        switch source {
        case .hand(let good):
            self.init(slot: slot, card: GoodsCard(good: good))
        }
    }
}
