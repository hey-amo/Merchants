public struct CubeSupply: Codable, Equatable, Sendable {
    public static let cubesPerGood = 5

    private var counts: [GoodType: Int]

    public init() {
        counts = Dictionary(
            uniqueKeysWithValues: GoodType.allCases.map { ($0, Self.cubesPerGood) }
        )
    }

    public init(restoring availableCounts: [GoodType: Int]) throws(CubeSupplyError) {
        var restored: [GoodType: Int] = [:]
        for good in GoodType.allCases {
            guard let count = availableCounts[good] else {
                throw .missingCount(good)
            }
            guard (0...Self.cubesPerGood).contains(count) else {
                throw .invalidCount(good: good, count: count)
            }
            restored[good] = count
        }
        counts = restored
    }

    public func available(of good: GoodType) -> Int {
        counts[good, default: 0]
    }

    public mutating func take(_ good: GoodType) throws(CubeSupplyError) -> GoodsCube {
        let count = available(of: good)
        guard count > 0 else {
            throw .noneAvailable(good)
        }
        counts[good] = count - 1
        return GoodsCube(good: good)
    }

    public mutating func returnCube(_ cube: GoodsCube) throws(CubeSupplyError) {
        let count = available(of: cube.good)
        guard count < Self.cubesPerGood else {
            throw .supplyFull(cube.good)
        }
        counts[cube.good] = count + 1
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var decodedCounts: [GoodType: Int] = [:]
        for good in GoodType.allCases {
            let count = try container.decode(Int.self, forKey: CodingKeys(good))
            decodedCounts[good] = count
        }
        try self.init(restoring: decodedCounts)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        for good in GoodType.allCases {
            try container.encode(available(of: good), forKey: CodingKeys(good))
        }
    }

    private enum CodingKeys: String, CodingKey {
        case sugar
        case indigo
        case spices
        case tea
        case silk
        case lumber

        init(_ good: GoodType) {
            switch good {
            case .sugar: self = .sugar
            case .indigo: self = .indigo
            case .spices: self = .spices
            case .tea: self = .tea
            case .silk: self = .silk
            case .lumber: self = .lumber
            }
        }
    }
}
