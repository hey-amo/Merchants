public struct GoodsCube: Codable, Equatable, Hashable, Sendable {
    public let good: GoodType

    public init(good: GoodType) {
        self.good = good
    }
}
