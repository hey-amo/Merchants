public struct GameState: Equatable, Sendable {
    public let configuration: GameConfiguration
    public let random: SeededRandomSource
    public internal(set) var deck: DrawDeck
    public internal(set) var hands: [Hand]
    public internal(set) var marketplace: Marketplace
    public internal(set) var bank: Bank
    public internal(set) var stock: SpecialCardStock
    public internal(set) var tableaux: [Tableau]
    public internal(set) var draft: CubeDraft
    public internal(set) var turn: TurnFlow?
    public internal(set) var ending: GameEnding
    public internal(set) var fleets: [Fleet]
    public internal(set) var supply: CubeSupply

    public init(configuration: GameConfiguration) throws {
        var random = SeededRandomSource(seed: configuration.seed)
        var deck = DeckBuilder.standardDeck(using: &random)
        var hands: [Hand] = []
        for _ in configuration.playerIDs {
            var hand = Hand()
            try hand.add(deck.draw(3), limit: configuration.rules.handLimitBase)
            hands.append(hand)
        }
        let market = try Marketplace(visibleCards: deck.draw(Marketplace.slotCount))
        let first = random.firstPlayer(in: configuration)
        guard let firstSeat = configuration.playerIDs.firstIndex(of: first) else {
            throw GameSetupError.unknownFirstPlayer
        }
        let order = try SeatOrder(count: configuration.playerIDs.count, first: firstSeat)
        let draft = CubeDraft(order: order)
        self.configuration = configuration
        self.random = random
        self.deck = deck
        self.hands = hands
        marketplace = market
        bank = try Bank(playerIDs: configuration.playerIDs)
        stock = try SpecialCardStock(playerCount: configuration.playerIDs.count, catalog: configuration.rules.specialCardCatalog)
        tableaux = Array(repeating: Tableau(), count: configuration.playerIDs.count)
        self.draft = draft
        turn = nil
        ending = GameEnding(rule: configuration.rules.endGameRule, order: order)
        fleets = draft.fleets
        supply = draft.supply
    }

    public func playerView(for player: PlayerID) throws -> PlayerView {
        guard let seat = configuration.playerIDs.firstIndex(of: player) else { throw EngineError.unknownPlayer }
        return PlayerView(player: player, hand: hands[seat].contents, handCounts: hands.map(\.count),
                          deckCount: deck.remaining, marketplaceCards: marketplace.visibleCards, bank: bank, fleets: fleets,
                          supply: supply, tableaux: tableaux, stock: stock, turn: turn, ending: ending,
                          draft: turn == nil ? draft : nil)
    }
}

public struct PlayerView: Equatable, Sendable {
    public let player: PlayerID
    public let hand: [GoodsCard]
    public let handCounts: [Int]
    public let deckCount: Int
    public let marketplaceCards: [GoodsCard]
    public let bank: Bank
    public let fleets: [Fleet]
    public let supply: CubeSupply
    public let tableaux: [Tableau]
    public let stock: SpecialCardStock
    public let turn: TurnFlow?
    public let ending: GameEnding
    public let draft: CubeDraft?
}
