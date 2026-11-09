public struct Marketplace: Codable, Equatable, Sendable {
    public static let slotCount = 6
    private var stacks: [[GoodsCard]]

    public var visibleCards: [GoodsCard] {
        stacks.map { $0[$0.count - 1] }
    }

    public var totalCardCount: Int {
        stacks.reduce(0) { $0 + $1.count }
    }

    public init(visibleCards: [GoodsCard]) throws(MarketplaceError) {
        guard visibleCards.count == Self.slotCount else { throw .invalidSlotCount }
        self.stacks = visibleCards.map { [$0] }
    }

    public func demand(for good: GoodType) -> Int {
        visibleCards.filter { $0.good == good }.count
    }

    public mutating func deliver(_ placements: [DeliveryPlacement]) throws(MarketplaceError) {
        guard let first = placements.first else { throw .emptyDelivery }
        guard placements.count <= Self.slotCount else { throw .tooManyCards }
        guard placements.allSatisfy({ $0.card.good == first.card.good }) else { throw .mixedGoods }
        guard placements.allSatisfy({ stacks.indices.contains($0.slot) }) else { throw .slotOutOfRange }
        guard Set(placements.map(\.slot)).count == placements.count else { throw .duplicateSlot }

        for placement in placements {
            stacks[placement.slot].append(placement.card)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let stacks = try container.decode([[GoodsCard]].self, forKey: .stacks)
        guard stacks.count == Self.slotCount, stacks.allSatisfy({ !$0.isEmpty }) else {
            throw MarketplaceError.invalidSlotCount
        }
        self.stacks = stacks
    }

    private enum CodingKeys: String, CodingKey {
        case stacks
    }
}
