// A validated, serializable non-negative coin balance.
// Owns balance restoration and atomic add/subtract operations.
// Does not know about players, banks, or reasons for coin changes.

public struct Coins: Codable, Equatable, Hashable, Sendable {
    public private(set) var available: Int

    public init(_ amount: Int = 0) throws(CoinError) {
        guard amount >= 0 else {
            throw .isNegativeNumber
        }
        available = amount
    }

    public mutating func perform(_ action: CoinAction) throws(CoinError) {
        switch action {
        case .add(let amount):
            guard amount >= 0 else {
                throw .isNegativeNumber
            }
            let (sum, overflowed) = available.addingReportingOverflow(amount)
            guard !overflowed else {
                throw .overflow
            }
            available = sum
        case .subtract(let amount):
            guard amount >= 0 else {
                throw .isNegativeNumber
            }
            guard available >= amount else {
                throw .insufficientFunds(required: amount, available: available)
            }
            available -= amount
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(container.decode(Int.self, forKey: .available))
    }

    private enum CodingKeys: String, CodingKey {
        case available
    }
}
