import Foundation
import Testing
@testable import MerchantsGame

@Suite("Engine error mappings")
struct EngineErrorTests {
    @Test func eachAvailableContextPreservesItsError() {
        let player = PlayerID("player")
        #expect(EngineError(CoinError.insufficientFunds(required: 4, available: 2)) ==
            .coins(.insufficientFunds(required: 4, available: 2)))
        #expect(EngineError(BankingError.unknownPlayer(player)) == .banking(.unknownPlayer(player)))
        #expect(EngineError(BankingError.coin(player: .overflow)) == .banking(.coin(player: .overflow)))
        #expect(EngineError(DrawDeckError.empty) == .drawDeck(.empty))
        #expect(EngineError(HandError.insufficientCards(good: .tea, required: 2, available: 1)) ==
            .hand(.insufficientCards(good: .tea, required: 2, available: 1)))
        #expect(EngineError(CubeSupplyError.noneAvailable(.sugar)) == .cubeSupply(.noneAvailable(.sugar)))
        #expect(EngineError(ShipError.sameGood) == .ships(.sameGood))
        #expect(EngineError(MarketplaceError.duplicateSlot) == .marketplace(.duplicateSlot))
        #expect(EngineError(SpecialCardError.outOfStock(.office)) == .specialCards(.outOfStock(.office)))
        #expect(EngineError(TurnFlowError.notYourTurn) == .turnFlow(.notYourTurn))
        #expect(EngineError(GameSetupError.duplicatePlayerID) == .setup(.duplicatePlayerID))
    }

    @Test func descriptionsIncludeContextAndErrorDetails() {
        let error = EngineError(HandError.invalidLimit(-1))
        #expect(error.description.contains("hand"))
        #expect(error.description.contains("limit"))
        #expect(error.description.contains("-1"))
        #expect(EngineError(TurnFlowError.wrongPhase).description.contains("turnFlow"))
    }

    @Test func descriptionsAreReadableAndIncludeRelevantDetails() {
        #expect(ShipError.sameGood.description == "Choose a cube of a different colour.")
        #expect(CoinError.insufficientFunds(required: 4, available: 2).description ==
            "Not enough coins: 4 required, 2 available.")
        #expect(HandError.invalidLimit(-1).description == "The hand limit -1 cannot be negative.")
        #expect(GameSetupError.invalidPlayerCount.description == "A game must have between 2 and 4 players.")
        #expect(SpecialCardError.outOfStock(.largeShip).description == "The Large Ship card is out of stock.")
        #expect(SpecialCardError.ownershipLimitReached(.customsHouse).description ==
            "The ownership limit for Customs House has been reached.")
        #expect(CubeDraftError.ship(.sameGood).description == ShipError.sameGood.description)
        #expect(PlanningError.turn(.wrongPhase).description == TurnFlowError.wrongPhase.description)
        #expect(EngineError.invalidAction.description == "This action is not available now.")
        #expect(GameStateError.cardCountMismatch.description == "The saved game has an incorrect number of cards.")
        let rejection = ActionRejection(error: .turnFlow(.wrongPhase), action: .drawCards, player: PlayerID("p"))
        #expect(rejection.description.contains("p"))
        #expect(rejection.description.contains(TurnFlowError.wrongPhase.description))
        #expect(EngineError(GameStateError.cardCountMismatch).description ==
            "state: The saved game has an incorrect number of cards.")
    }

    @Test func genericLocalizedMessageKeepsTheUnderlyingErrorDetail() {
        let errors: [EngineError] = [
            .turnFlow(.wrongPhase),
            .invalidAction,
            .unexpected("An unknown problem occurred.")
        ]
        for error in errors {
            let expected = "Game error -- \(error.description)"
            #expect(error.localizedDescription == expected)
            let rejection = ActionRejection(error: error, action: .drawCards, player: PlayerID("player"))
            #expect(rejection.localizedDescription == expected)
            let erased: any Error = rejection
            #expect(erased.localizedDescription == expected)
            #expect(rejection.description.contains("player"))
        }
    }

    @Test func actualRejectedActionExposesGenericLocalizedMessage() throws {
        let players = [PlayerID("one"), PlayerID("two")]
        let state = try GameState(configuration: GameConfiguration(
            playerIDs: players, seed: 1, firstPlayer: .fixed(players[0])
        ))
        do {
            _ = try GameEngine.apply(.drawCards, by: players[0], to: state)
            Issue.record("Expected an action rejection")
        } catch {
            #expect(error.error == .invalidAction)
            #expect(error.localizedDescription == "Game error -- This action is not available now.")
        }
    }

    @Test func addedContextAndPlanningMappingsPreserveErrors() {
        #expect(EngineError(CubeDraftError.notDraftingSeat) == .draft(.notDraftingSeat))
        #expect(EngineError(TradingPhaseError.invalidPlayerState) == .trading(.invalidPlayerState))
        #expect(EngineError(DeliveryScoringError.overflow) == .deliveryScoring(.overflow))
        #expect(EngineError(GameEndingError.alreadyEnded) == .gameEnding(.alreadyEnded))
        #expect(EngineError(GameStateError.cardCountMismatch) == .state(.cardCountMismatch))
        #expect(EngineError(PlanningError.turn(.wrongPhase)) == .turnFlow(.wrongPhase))
        #expect(EngineError(PlanningError.banking(.coin(player: .overflow))) == .banking(.coin(player: .overflow)))
        #expect(EngineError(PlanningError.supply(.noneAvailable(.tea))) == .cubeSupply(.noneAvailable(.tea)))
        #expect(EngineError(PlanningError.ship(.sameGood)) == .ships(.sameGood))
        #expect(EngineError(PlanningError.specialCard(.outOfStock(.office))) == .specialCards(.outOfStock(.office)))
        #expect(EngineError(PlanningError.unknownPlayer) == .unknownPlayer)
        #expect(EngineError(PlanningError.invalidState) == .planning(.invalidState))
        #expect(EngineError(PlanningError.invalidShipLoad) == .planning(.invalidShipLoad))
    }

    @Test func mappedBankRejectionPreservesState() throws {
        let player = PlayerID("player")
        var bank = try Bank(playerIDs: [player])
        let initial = bank
        let transaction = Transaction(player: player, amount: 1, direction: .debit, reason: .specialCardPurchase(.office))
        do {
            try bank.apply([transaction])
            Issue.record("Expected an insufficient-funds rejection")
        } catch {
            let mapped = EngineError(error)
            #expect(mapped == .banking(.coin(player: .insufficientFunds(required: 1, available: 0))))
            #expect(bank == initial)
        }
    }
}
