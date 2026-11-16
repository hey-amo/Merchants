public struct Ship: Codable, Equatable, Sendable {
    public enum Kind: Codable, Equatable, Sendable {
        case standard
        case large

        public var capacity: Int {
            switch self {
            case .standard: 1
            case .large: 2
            }
        }
    }

    public let kind: Kind
    public private(set) var cubes: [GoodsCube]

    public init(kind: Kind) {
        self.kind = kind
        self.cubes = []
    }

    mutating func load(_ cube: GoodsCube) throws(ShipError) {
        guard cubes.count < kind.capacity else { throw .capacityExceeded }
        cubes.append(cube)
    }

    mutating func exchange(cubeIndex: Int, for cube: GoodsCube) throws(ShipError) -> GoodsCube {
        guard cubes.indices.contains(cubeIndex) else { throw .cubeIndexOutOfRange }
        let removed = cubes[cubeIndex]
        guard removed.good != cube.good else { throw .sameGood }
        cubes[cubeIndex] = cube
        return removed
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        let cubes = try container.decode([GoodsCube].self, forKey: .cubes)
        guard cubes.count <= kind.capacity else { throw ShipError.capacityExceeded }
        self.kind = kind
        self.cubes = cubes
    }

    private enum CodingKeys: String, CodingKey {
        case kind, cubes
    }
}
