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
        #expect(error.description.contains("invalidLimit"))
        #expect(error.description.contains("-1"))
        #expect(EngineError(TurnFlowError.wrongPhase).description.contains("turnFlow"))
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
