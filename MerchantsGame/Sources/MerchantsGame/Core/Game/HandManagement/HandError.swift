public enum HandError: Error, Equatable, Sendable {
    case limitExceeded(limit: Int, attempted: Int)
    case insufficientCards(good: GoodType, required: Int, available: Int)
    case invalidLimit(Int)
    case invalidCount(Int)
}
