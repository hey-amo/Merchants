public struct Tableau: Codable, Equatable, Sendable {
    private var counts: [SpecialCardKind: Int] = [:]

    public init() {}

    public func count(of kind: SpecialCardKind) -> Int {
        counts[kind, default: 0]
    }

    mutating func add(_ kind: SpecialCardKind) throws(SpecialCardError) {
        let (count, overflow) = count(of: kind).addingReportingOverflow(1)
        guard !overflow else { throw .overflow }
        counts[kind] = count
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let counts = try container.decode([SpecialCardKind: Int].self, forKey: .counts)
        guard counts.values.allSatisfy({ $0 >= 0 }) else { throw SpecialCardError.invalidTableau }
        self.counts = counts
    }

    private enum CodingKeys: String, CodingKey { case counts }
}
