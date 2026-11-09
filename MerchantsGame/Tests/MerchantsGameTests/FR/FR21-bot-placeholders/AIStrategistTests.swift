import Testing
@testable import MerchantsGame

@Suite("AI strategist")
struct AIStrategistTests {
    private let botID = PlayerID("bot")
    private let rivalID = PlayerID("rival")

    @Test func aggressiveStrategistBuysAnIncomeShipBeforeExchanging() throws {
        let observation = try makeObservation(
            phase: .planning,
            hand: [.sugar],
            market: [.sugar, .tea, .tea, .indigo, .silk, .lumber],
            ownFleet: fleet([.sugar, .tea]),
            coins: 40
        )
        let actions: [GameAction] = [
            .exchangeCube(ship: 1, cubeIndex: 0, good: .sugar),
            .buySpecialCard(kind: .ship, loadCubes: [.sugar]),
            .passPlanning
        ]

        let decision = try #require(
            AIStrategist(personality: .aggressive, logger: { _ in })
                .decide(for: observation, legalActions: actions)
        )

        #expect(decision.action == .buySpecialCard(kind: .ship, loadCubes: [.sugar]))
        #expect(decision.message.hasPrefix("Phase 1: Bot made a decision to"))
    }

    @Test func conservativeStrategistTakesAProfitableExchangeInsteadOfSpending() throws {
        let observation = try makeObservation(
            phase: .planning,
            hand: [.sugar],
            market: [.sugar, .tea, .tea, .indigo, .silk, .lumber],
            ownFleet: fleet([.sugar, .tea]),
            coins: 40
        )
        let actions: [GameAction] = [
            .exchangeCube(ship: 1, cubeIndex: 0, good: .sugar),
            .buySpecialCard(kind: .ship, loadCubes: [.sugar]),
            .passPlanning
        ]

        let selected = AIStrategist(personality: .conservative, logger: { _ in })
            .chooseAction(for: observation, legalActions: actions)

        #expect(selected == .exchangeCube(ship: 1, cubeIndex: 0, good: .sugar))
    }

    @Test func purchaseMustBeAffordableEvenIfListedAsLegal() throws {
        let observation = try makeObservation(
            phase: .planning,
            hand: [],
            coins: 0
        )
        let actions: [GameAction] = [
            .buySpecialCard(kind: .ship, loadCubes: [.sugar]),
            .passPlanning
        ]

        let selected = AIStrategist(logger: { _ in }).chooseAction(
            for: observation,
            legalActions: actions
        )

        #expect(selected == .passPlanning)
    }

    @Test func purchaseRejectsInvalidShipLoadsAndCubeLoadsOnOtherCards() throws {
        let observation = try makeObservation(
            phase: .planning,
            hand: [],
            coins: 40
        )
        let actions: [GameAction] = [
            .buySpecialCard(kind: .ship, loadCubes: []),
            .buySpecialCard(kind: .ship, loadCubes: [.sugar, .sugar]),
            .buySpecialCard(kind: .office, loadCubes: [.sugar]),
            .passPlanning
        ]

        let selected = AIStrategist(logger: { _ in }).chooseAction(
            for: observation,
            legalActions: actions
        )

        #expect(selected == .passPlanning)
    }

    @Test func deliveryForecastUsesTheNewMarketAndAllPlayersShips() throws {
        let observation = try makeObservation(
            phase: .trading,
            hand: [.sugar, .sugar, .tea],
            market: [.sugar, .tea, .tea, .indigo, .silk, .lumber],
            ownFleet: fleet([.sugar]),
            rivalFleet: fleet([.tea, .tea])
        )
        let sugarDelivery: [DeliveryPlacement] = [
            DeliveryPlacement(slot: 1, source: .hand(.sugar)),
            DeliveryPlacement(slot: 2, source: .hand(.sugar))
        ]
        let teaDelivery: [DeliveryPlacement] = [
            DeliveryPlacement(slot: 0, source: .hand(.tea)),
            DeliveryPlacement(slot: 3, source: .hand(.tea))
        ]

        let decision = try #require(
            AIStrategist(personality: .aggressive, logger: { _ in }).decide(
                for: observation,
                legalActions: [.deliverCards(teaDelivery), .deliverCards(sugarDelivery)]
            )
        )

        #expect(decision.action == .deliverCards(sugarDelivery))
        #expect(decision.message.contains("projects a 3-coin payout"))
    }

    @Test func conservativeProfileAccountsForRivalPayouts() throws {
        var ownFleet = try fleet([.sugar, .sugar])
        ownFleet.addShip(kind: .standard)
        try ownFleet.load(GoodsCube(good: .tea), onto: 2)
        let observation = try makeObservation(
            phase: .trading,
            hand: [.sugar, .sugar, .tea],
            market: [.sugar, .tea, .tea, .indigo, .silk, .lumber],
            ownFleet: ownFleet,
            rivalFleet: fleet([.sugar, .sugar])
        )
        let sugarDelivery = [
            DeliveryPlacement(slot: 1, source: .hand(.sugar)),
            DeliveryPlacement(slot: 2, source: .hand(.sugar))
        ]
        let teaDelivery = [DeliveryPlacement(slot: 0, source: .hand(.tea))]
        let actions: [GameAction] = [.deliverCards(sugarDelivery), .deliverCards(teaDelivery)]

        let aggressive = AIStrategist(personality: .aggressive, logger: { _ in })
            .chooseAction(for: observation, legalActions: actions)
        let conservative = AIStrategist(personality: .conservative, logger: { _ in })
            .chooseAction(for: observation, legalActions: actions)

        #expect(aggressive == .deliverCards(sugarDelivery))
        #expect(conservative == .deliverCards(teaDelivery))
    }

    @Test func conservativeProfileAvoidsEnrichingTheCurrentLeader() throws {
        let ownFleet = try fleet([.sugar, .sugar, .sugar, .sugar, .tea, .tea])
        let market: [GoodType] = [.sugar, .tea, .indigo, .silk, .lumber, .spices]
        let sugarDelivery = [
            DeliveryPlacement(slot: 1, source: .hand(.sugar)),
            DeliveryPlacement(slot: 2, source: .hand(.sugar))
        ]
        let teaDelivery = [
            DeliveryPlacement(slot: 0, source: .hand(.tea)),
            DeliveryPlacement(slot: 2, source: .hand(.tea))
        ]
        let actions: [GameAction] = [.deliverCards(sugarDelivery), .deliverCards(teaDelivery)]
        let trailingRival = try makeObservation(
            phase: .trading,
            hand: [.sugar, .sugar, .tea, .tea],
            market: market,
            ownFleet: ownFleet,
            rivalFleet: fleet([.sugar]),
            coins: 40,
            rivalCoins: 0
        )
        let leadingRival = try makeObservation(
            phase: .trading,
            hand: [.sugar, .sugar, .tea, .tea],
            market: market,
            ownFleet: ownFleet,
            rivalFleet: fleet([.sugar]),
            coins: 40,
            rivalCoins: 50
        )
        let conservative = AIStrategist(personality: .conservative, logger: { _ in })

        #expect(conservative.chooseAction(for: trailingRival, legalActions: actions) == .deliverCards(sugarDelivery))
        #expect(conservative.chooseAction(for: leadingRival, legalActions: actions) == .deliverCards(teaDelivery))
    }

    @Test func tradeAgreementBonusIsIncludedInDeliveryMessage() throws {
        var tableau = Tableau()
        try tableau.add(.tradeAgreement)
        let observation = try makeObservation(
            phase: .trading,
            hand: [.sugar, .sugar],
            market: [.sugar, .tea, .tea, .indigo, .silk, .lumber],
            ownFleet: fleet([.sugar]),
            ownTableau: tableau
        )
        let placements = [
            DeliveryPlacement(slot: 1, source: .hand(.sugar)),
            DeliveryPlacement(slot: 2, source: .hand(.sugar))
        ]

        let decision = try #require(
            AIStrategist(logger: { _ in }).decide(
                for: observation,
                legalActions: [.deliverCards(placements)]
            )
        )

        #expect(decision.message.contains("projects a 5-coin payout"))
    }

    @Test func drawsToBuildItsHandWhenItHasFewerThanThreeCards() throws {
        let observation = try makeObservation(
            phase: .trading,
            hand: [.sugar, .tea],
            market: [.sugar, .tea, .tea, .indigo, .silk, .lumber],
            ownFleet: fleet([.sugar])
        )
        let delivery = [DeliveryPlacement(slot: 1, source: .hand(.sugar))]

        let selected = AIStrategist(logger: { _ in }).chooseAction(
            for: observation,
            legalActions: [.deliverCards(delivery), .drawCards]
        )

        #expect(selected == .drawCards)
    }

    @Test func deliversWhenDrawingIsUnavailableAndSkipsOnlyWhenDeckIsEmpty() throws {
        let observation = try makeObservation(
            phase: .trading,
            hand: [.sugar, .sugar, .tea],
            market: [.sugar, .tea, .tea, .indigo, .silk, .lumber],
            deckCount: 0
        )
        let delivery = [DeliveryPlacement(slot: 1, source: .hand(.sugar))]
        let bot = AIStrategist(logger: { _ in })

        #expect(bot.chooseAction(for: observation, legalActions: [.skipTrading, .deliverCards(delivery)]) == .deliverCards(delivery))
        #expect(bot.chooseAction(for: observation, legalActions: [.skipTrading]) == .skipTrading)
    }

    @Test func additionalExchangeDoesNotReuseShipsAndCanEndPlanning() throws {
        let observation = try makeObservation(
            phase: .additionalExchange(
                remaining: 1,
                shipsAlreadyExchanged: [0],
                shipsAddedThisTurn: []
            ),
            hand: [.sugar],
            market: [.sugar, .tea, .tea, .indigo, .silk, .lumber],
            ownFleet: fleet([.tea, .sugar])
        )
        let actions: [GameAction] = [
            .exchangeCube(ship: 0, cubeIndex: 0, good: .sugar),
            .exchangeCube(ship: 1, cubeIndex: 0, good: .sugar),
            .endPlanning
        ]

        let selected = AIStrategist(logger: { _ in }).chooseAction(
            for: observation,
            legalActions: actions
        )

        #expect(selected == .endPlanning)
    }

    @Test func rejectsInvalidMockSnapshots() throws {
        let stock = try SpecialCardStock(playerCount: 2, catalog: .standard)
        let players = [
            StrategistPlayerObservation(player: botID, coins: 0, fleet: Fleet(), tableau: Tableau()),
            StrategistPlayerObservation(player: rivalID, coins: 0, fleet: Fleet(), tableau: Tableau())
        ]

        #expect(throws: StrategistInputError.invalidMarketplace) {
            try StrategistObservation(
                phase: .trading,
                player: botID,
                hand: [],
                marketplace: [],
                players: players,
                supply: CubeSupply(),
                stock: stock,
                deckCount: 10
            )
        }
    }

    private func makeObservation(
        phase: StrategistPhase,
        hand: [GoodType] = [],
        market: [GoodType] = GoodType.allCases,
        ownFleet: Fleet = Fleet(),
        rivalFleet: Fleet = Fleet(),
        ownTableau: Tableau = Tableau(),
        rivalTableau: Tableau = Tableau(),
        coins: Int = 40,
        rivalCoins: Int = 0,
        deckCount: Int = 30
    ) throws -> StrategistObservation {
        let rules = GameRules.standard
        let stock = try SpecialCardStock(playerCount: 2, catalog: rules.specialCardCatalog)
        let players = [
            StrategistPlayerObservation(player: botID, coins: coins, fleet: ownFleet, tableau: ownTableau),
            StrategistPlayerObservation(player: rivalID, coins: rivalCoins, fleet: rivalFleet, tableau: rivalTableau)
        ]
        return try StrategistObservation(
            phase: phase,
            player: botID,
            hand: hand.map { GoodsCard(good: $0) },
            marketplace: market.map { GoodsCard(good: $0) },
            players: players,
            supply: CubeSupply(),
            stock: stock,
            deckCount: deckCount,
            rules: rules
        )
    }

    private func fleet(_ goods: [GoodType]) throws -> Fleet {
        var fleet = Fleet()
        for (index, good) in goods.enumerated() {
            if index >= fleet.ships.count {
                fleet.addShip(kind: .standard)
            }
            try fleet.load(GoodsCube(good: good), onto: index)
        }
        return fleet
    }
}
