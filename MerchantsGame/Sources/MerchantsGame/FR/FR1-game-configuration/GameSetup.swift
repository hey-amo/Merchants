// Builds the initial domain values for a configured game.
// Keeps the shuffled deck and dealt hands internal to the game package.
// Does not apply turns or manage a live session.

struct GameSetup: Equatable, Sendable {
    let configuration: GameConfiguration
    let random: SeededRandomSource
    let deck: DrawDeck
    let hands: [Hand]
    let marketplace: Marketplace
    let bank: Bank
    let specialCardStock: SpecialCardStock
    let tableaus: [Tableau]
    let draft: CubeDraft

    init(configuration: GameConfiguration) throws {
        var random = SeededRandomSource(seed: configuration.seed)
        var deck = DeckBuilder.standardDeck(using: &random)
        var hands: [Hand] = []
        for _ in configuration.playerIDs {
            var hand = Hand()
            try hand.add(deck.draw(3), limit: configuration.rules.handLimitBase)
            hands.append(hand)
        }
        let marketplace = try Marketplace(visibleCards: deck.draw(Marketplace.slotCount))
        let first = random.firstPlayer(in: configuration)
        guard let firstSeat = configuration.playerIDs.firstIndex(of: first) else {
            throw GameSetupError.unknownFirstPlayer
        }
        let order = try SeatOrder(count: configuration.playerIDs.count, first: firstSeat)

        self.configuration = configuration
        self.random = random
        self.deck = deck
        self.hands = hands
        self.marketplace = marketplace
        self.bank = try Bank(playerIDs: configuration.playerIDs)
        self.specialCardStock = try SpecialCardStock(
            playerCount: configuration.playerIDs.count,
            catalog: configuration.rules.specialCardCatalog
        )
        self.tableaus = Array(repeating: Tableau(), count: configuration.playerIDs.count)
        self.draft = CubeDraft(order: order)
    }
}
