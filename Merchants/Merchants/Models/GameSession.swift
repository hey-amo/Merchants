import Foundation
import Observation

enum GameSessionStage: Equatable {
    case cubeDraft
    case phase1
    case phase2
    case finished
}

enum GameSessionError: LocalizedError {
    case wrongStage
    case noCubesAvailable
    case invalidCubeSelection
    case unavailableSpecialCard
    case insufficientFunds
    case noCardsAvailable
    case invalidDelivery
    case phase2ActionRequired
    case officeBonusMustBeResolved

    var errorDescription: String? {
        switch self {
        case .wrongStage:
            "That action isn't available right now."
        case .noCubesAvailable:
            "No cubes of that colour are available."
        case .invalidCubeSelection:
            "Choose a cube that is available to this player."
        case .unavailableSpecialCard:
            "That special card is no longer available."
        case .insufficientFunds:
            "This player doesn't have enough coins."
        case .noCardsAvailable:
            "There are no cards available to draw."
        case .invalidDelivery:
            "Choose a colour in your hand and a different marketplace space for each card."
        case .phase2ActionRequired:
            "Complete a Phase 2 action before ending the turn."
        case .officeBonusMustBeResolved:
            "Choose whether to draw the Office card before ending the turn."
        }
    }
}

@Observable
@MainActor
final class GameSession: Hashable {
    let id: UUID
    let players: [Player]
    let game: MerchantsGame
    private let draftOrder: [Int]
    private var draftIndex = 0

    var stage: GameSessionStage = .cubeDraft
    var phase1ActionCompleted = false
    var dockerExchangesRemaining = 0
    var phase2ActionCompleted = false
    var officeBonusResolved = false
    var revision = 0
    var errorMessage: String?

    init(players: [Player], id: UUID = UUID()) {
        let shuffledPlayers = players.shuffled()
        self.players = shuffledPlayers
        self.id = id
        self.draftOrder = Array(shuffledPlayers.indices.reversed()) + Array(shuffledPlayers.indices)

        if let firstPlayer = shuffledPlayers.first {
            firstPlayer.isStartPlayer = true
        }

        let game = MerchantsGame(
            buildings: BuildingDefinition.makeDeck().shuffled(),
            drawPile: [],
            cubePile: [],
            players: shuffledPlayers
        )
        self.game = game
        game.newGame(players: shuffledPlayers)
        updatePlayerStates(activePlayer: activePlayer)
    }

    var activePlayer: Player? {
        switch stage {
        case .cubeDraft:
            guard draftOrder.indices.contains(draftIndex) else { return nil }
            return players[draftOrder[draftIndex]]
        case .phase1, .phase2:
            return game.activePlayer
        case .finished:
            return nil
        }
    }

    var availableSpecialCards: [BuildingDefinition] {
        var seenNames = Set<String>()
        return game.buildings
            .filter { seenNames.insert($0.name).inserted }
            .sorted { $0.name < $1.name }
    }

    var isDraftComplete: Bool {
        stage != .cubeDraft
    }

    var dockerExchangeAvailable: Bool {
        phase1ActionCompleted && dockerExchangesRemaining > 0
    }

    var officeBonusAvailable: Bool {
        guard stage == .phase2,
              phase2ActionCompleted,
              let player = game.activePlayer else {
            return false
        }
        return player.tableau.contains { $0.name == "Office" } &&
            player.hand.count < GameConstants.maxHandSize &&
            !game.drawPile.isEmpty
    }

    func availableCubeCount(for color: GoodsCube) -> Int {
        game.cubePile.filter { $0 == color }.count
    }

    func selectDraftCube(_ color: GoodsCube) throws {
        guard stage == .cubeDraft else { throw GameSessionError.wrongStage }
        guard let player = activePlayer, player.cubes.count < 2 else {
            throw GameSessionError.invalidCubeSelection
        }
        guard let cubeIndex = game.cubePile.firstIndex(of: color) else {
            throw GameSessionError.noCubesAvailable
        }

        game.cubePile.remove(at: cubeIndex)
        player.cubes.append(color)
        draftIndex += 1

        if draftIndex == draftOrder.count {
            stage = .phase1
            game.currentState = .phase1
            game.currentTurnPhase = .phase1
        }
        updatePlayerStates(activePlayer: activePlayer)
        revision += 1
    }

    func passPhase1() throws {
        try requireStage(.phase1)
        guard !phase1ActionCompleted else { throw GameSessionError.wrongStage }
        completePhase1Action()
    }

    func exchangeCube(at index: Int, for color: GoodsCube) throws {
        try requireStage(.phase1)
        guard !phase1ActionCompleted || dockerExchangeAvailable else {
            throw GameSessionError.wrongStage
        }
        guard let player = game.activePlayer,
              player.cubes.indices.contains(index),
              player.cubes[index] != color else {
            throw GameSessionError.invalidCubeSelection
        }
        guard let availableIndex = game.cubePile.firstIndex(of: color) else {
            throw GameSessionError.noCubesAvailable
        }

        game.cubePile.remove(at: availableIndex)
        game.cubePile.append(player.cubes[index])
        player.cubes[index] = color
        if phase1ActionCompleted {
            dockerExchangesRemaining -= 1
            if dockerExchangesRemaining == 0 {
                beginPhase2()
            } else {
                revision += 1
            }
        } else {
            completePhase1Action()
        }
    }

    func buySpecialCard(named name: String, shipCube: GoodsCube? = nil) throws {
        try requireStage(.phase1)
        guard !phase1ActionCompleted else { throw GameSessionError.wrongStage }
        guard let player = game.activePlayer,
              let buildingIndex = game.buildings.firstIndex(where: { $0.name == name }) else {
            throw GameSessionError.unavailableSpecialCard
        }
        let building = game.buildings[buildingIndex]
        guard player.coins >= building.cost else {
            throw GameSessionError.insufficientFunds
        }

        if building.name == "Ship" {
            guard let shipCube,
                  let cubeIndex = game.cubePile.firstIndex(of: shipCube) else {
                throw GameSessionError.noCubesAvailable
            }
            game.cubePile.remove(at: cubeIndex)
            player.cubes.append(shipCube)
        }

        player.coins -= building.cost
        player.tableau.append(building)
        game.buildings.remove(at: buildingIndex)
        completePhase1Action()
    }

    func finishPhase1() throws {
        try requireStage(.phase1)
        guard dockerExchangeAvailable else { throw GameSessionError.wrongStage }
        beginPhase2()
    }

    func resolveOfficeBonus(drawCard: Bool) throws {
        try requireStage(.phase2)
        guard !officeBonusResolved, officeBonusAvailable,
              let player = game.activePlayer else {
            throw GameSessionError.wrongStage
        }
        if drawCard {
            player.hand.append(game.drawPile.removeFirst())
        }
        officeBonusResolved = true
        revision += 1
    }

    func deliverGoods(color: GoodsCube, to marketplaceSlots: [Int]) throws {
        try requireStage(.phase2)
        guard !phase2ActionCompleted,
              let player = game.activePlayer,
              !marketplaceSlots.isEmpty,
              Set(marketplaceSlots).count == marketplaceSlots.count,
              marketplaceSlots.allSatisfy(game.marketplace.indices.contains) else {
            throw GameSessionError.invalidDelivery
        }

        let matchingCards = player.hand.filter { $0 == color }.count
        guard matchingCards >= marketplaceSlots.count else {
            throw GameSessionError.invalidDelivery
        }

        var cardsToRemove = marketplaceSlots.count
        player.hand.removeAll { card in
            guard card == color, cardsToRemove > 0 else { return false }
            cardsToRemove -= 1
            return true
        }
        for slot in marketplaceSlots {
            game.marketplace[slot] = color
        }

        let demand = game.marketplace.filter { $0 == color }.count
        for scoringPlayer in players {
            let matchingCubes = scoringPlayer.cubes.filter { $0 == color }.count
            scoringPlayer.coins += matchingCubes * demand
        }
        let tradeAgreements = player.tableau.filter { $0.name == "Trade agreement" }.count
        player.coins += tradeAgreements * 2
        completePhase2Action()
    }

    func drawTwoCards() throws {
        try requireStage(.phase2)
        guard !phase2ActionCompleted else { throw GameSessionError.wrongStage }
        guard let player = game.activePlayer else { throw GameSessionError.wrongStage }

        let availableHandSpace = GameConstants.maxHandSize - player.hand.count
        let cardsToDraw = min(2, availableHandSpace, game.drawPile.count)
        guard cardsToDraw > 0 else { throw GameSessionError.noCardsAvailable }

        player.hand.append(contentsOf: game.drawPile.prefix(cardsToDraw))
        game.drawPile.removeFirst(cardsToDraw)
        completePhase2Action()
    }

    func endTurn() throws {
        try requireStage(.phase2)
        guard phase2ActionCompleted else { throw GameSessionError.phase2ActionRequired }
        if officeBonusAvailable && !officeBonusResolved {
            throw GameSessionError.officeBonusMustBeResolved
        }

        phase2ActionCompleted = false
        officeBonusResolved = false
        if game.drawPile.isEmpty {
            stage = .finished
            game.currentState = .gameOver
            updatePlayerStates(activePlayer: nil, completedPlayer: game.activePlayer)
        } else {
            let completedPlayer = game.activePlayer
            _ = game.advanceTurn()
            stage = .phase1
            game.currentState = .phase1
            game.currentTurnPhase = .phase1
            updatePlayerStates(activePlayer: game.activePlayer, completedPlayer: completedPlayer)
        }
        revision += 1
    }

    private func completePhase2Action() {
        phase2ActionCompleted = true
        officeBonusResolved = false
        revision += 1
    }

    private func completePhase1Action() {
        phase1ActionCompleted = true
        dockerExchangesRemaining = game.activePlayer?.tableau
            .filter { $0.name == "Docker" }
            .count ?? 0
        if dockerExchangesRemaining == 0 {
            beginPhase2()
        } else {
            revision += 1
        }
    }

    private func beginPhase2() {
        phase1ActionCompleted = false
        dockerExchangesRemaining = 0
        stage = .phase2
        game.currentState = .phase2
        game.currentTurnPhase = .phase2
        revision += 1
    }

    private func requireStage(_ requiredStage: GameSessionStage) throws {
        guard stage == requiredStage else { throw GameSessionError.wrongStage }
    }

    private func updatePlayerStates(activePlayer: Player?, completedPlayer: Player? = nil) {
        for player in players {
            player.state = player === completedPlayer ? .done : .idle
        }
        activePlayer?.state = .thinking
    }

    nonisolated static func == (lhs: GameSession, rhs: GameSession) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
