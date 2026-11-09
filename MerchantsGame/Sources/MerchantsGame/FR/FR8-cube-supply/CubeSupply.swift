public struct CubeSupply: Codable, Equatable, Sendable {
    public static let cubesPerGood = 5

    private var counts: GoodCounts

    public init() {
        counts = GoodCounts(repeating: Self.cubesPerGood)
    }

    public init(restoring availableCounts: [GoodType: Int]) throws(CubeSupplyError) {
        var restored = GoodCounts(repeating: 0)
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
        counts[good]
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
            guard let count = try container.decodeIfPresent(
                Int.self,
                forKey: CodingKeys(good)
            ) else {
                throw CubeSupplyError.missingCount(good)
            }
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

    private struct GoodCounts: Equatable, Sendable {
        var sugar: Int
        var indigo: Int
        var spices: Int
        var tea: Int
        var silk: Int
        var lumber: Int

        init(repeating count: Int) {
            sugar = count
            indigo = count
            spices = count
            tea = count
            silk = count
            lumber = count
        }

        subscript(good: GoodType) -> Int {
            get {
                switch good {
                case .sugar: sugar
                case .indigo: indigo
                case .spices: spices
                case .tea: tea
                case .silk: silk
                case .lumber: lumber
                }
            }
            set {
                switch good {
                case .sugar: sugar = newValue
                case .indigo: indigo = newValue
                case .spices: spices = newValue
                case .tea: tea = newValue
                case .silk: silk = newValue
                case .lumber: lumber = newValue
                }
            }
        }
    }
}
