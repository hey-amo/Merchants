public struct Transaction: Codable, Equatable, Sendable {
    public let player: PlayerID
    public let amount: Int
    public let direction: TransactionDirection
    public let reason: TransactionReason

    public init(
        player: PlayerID,
        amount: Int,
        direction: TransactionDirection,
        reason: TransactionReason
    ) {
        self.player = player
        self.amount = amount
        self.direction = direction
        self.reason = reason
    }
}
