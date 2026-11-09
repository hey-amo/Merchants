public struct DeliveryPlacement: Codable, Equatable, Sendable {
    public let slot: Int
    public let card: GoodsCard

    public init(slot: Int, card: GoodsCard) {
        self.slot = slot
        self.card = card
    }
}
