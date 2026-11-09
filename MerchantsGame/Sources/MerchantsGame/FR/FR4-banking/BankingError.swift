public enum BankingError: Error, Equatable, Sendable {
    case unknownPlayer(PlayerID)
    case coin(player: CoinError)
}
