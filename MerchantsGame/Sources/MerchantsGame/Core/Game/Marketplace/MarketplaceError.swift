public enum MarketplaceError: Error, Equatable, Sendable {
    case invalidSlotCount
    case emptyDelivery
    case mixedGoods
    case duplicateSlot
    case slotOutOfRange
    case tooManyCards
}
