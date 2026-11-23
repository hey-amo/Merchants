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
    public private(set) var cargo: [GoodsCube] // A ship has cargo of goods cubes (:crates)

    public init(kind: Kind, cargo: [GoodsCube] = [GoodsCube]()) {
        self.kind = kind
        self.cargo = []
    }

    // add a crate to the ship
    mutating func load(_ crate: GoodsCube) throws(ShipError) {
        guard cargo.count < kind.capacity else { throw .capacityExceeded }
        cargo.append(crate)
    }

    mutating func exchange(cubeIndex: Int, for cube: GoodsCube) throws(ShipError) -> GoodsCube {
        guard cargo.indices.contains(cubeIndex) else { throw .cubeIndexOutOfRange }
        let removed = cargo[cubeIndex]
        guard removed.good != cube.good else { throw .sameGood }
        cargo[cubeIndex] = cube
        return removed
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        let cargo = try container.decode([GoodsCube].self, forKey: .cargo)
        guard cargo.count <= kind.capacity else { throw ShipError.capacityExceeded }
        self.kind = kind
        self.cargo = cargo
    }

    private enum CodingKeys: String, CodingKey {
        case kind, cargo
    }
}
