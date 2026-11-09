public enum CubeSupplyError: Error, Equatable, Sendable {
    case noneAvailable(GoodType)
    case supplyFull(GoodType)
    case invalidCount(good: GoodType, count: Int)
    case missingCount(GoodType)
}
