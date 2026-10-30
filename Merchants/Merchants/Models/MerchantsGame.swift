//
//  MerchantsGame.swift
//  Merchants
//
//  Created by Amarjit on 29/06/2026.
//
import GameplayKit
import Foundation

enum GameState: Int, CaseIterable, Codable {
    case setup, playerSelect, paused, phase1, phase2, gameOver
}

enum PlayerState: Int, CaseIterable, Codable {
    case idle, busy, thinking, done

    var displayName: String {
        switch self {
        case .idle: "Idle"
        case .busy: "Busy"
        case .thinking: "Thinking"
        case .done: "Done"
        }
    }
}

struct TurnPhase: Equatable, Codable {
    let id: String
    let name: String
    let actions: [TurnAction]
}

struct TurnAction: Equatable, Codable {
    let id: String
    let name: String
}


// Phase 1: Exchange goods cube, Buy building, Pass
// Phase 2: Play good cards, Draw good cards, End turn
extension TurnPhase {
    static let phase1 = TurnPhase(
        id: "phase1",
        name: "Phase 1",
        actions: [
            TurnAction(id: "exchangeGoodsCube", name: "Exchange goods cube"),
            TurnAction(id: "buyBuilding", name: "Buy building"),
            TurnAction(id: "pass", name: "Pass")
        ]
    )

    static let phase2 = TurnPhase(
        id: "phase2",
        name: "Phase 2",
        actions: [
            TurnAction(id: "playGoodCards", name: "Play good cards"),
            TurnAction(id: "drawGoodCards", name: "Draw good cards"),
            TurnAction(id: "endTurn", name: "End turn")
        ]
    )
}

/* 
 6 different goods:
    Sugar (White), Indigo (Blue), Spices (Red), 10x Tea (Green), 10x Silk (Purple), 10x Lumber (Brown)
 60 good cards
 - 10x Sugar (White), 10x Indigo (Blue), 10x Spices (Red), 10x Tea (Green), 10x Silk (Purple), 10x Lumber (Brown)

 30 good cubes in the 6 different goods
     - 5x Sugar (White), 5x Indigo (Blue), 5x Spices (Red), 5x Tea (Green), 5x Silk (Purple), 5x Lumber (Brown)

 20 special cards
     - 14x ship (10 coins) - players start with 2 ships; each ship carries 1 goods cube
     - 2x office (8 coins) - draw 1 goods card at the end of Phase 2
     - 2x docker (12 coins) - exchange an extra goods cube during Phase 1
     - 2x trade agreement (11 coins) - receive 2 additional coins when you deliver
*/

// In-game constants
struct GameConstants {
    public static let totalGoodCards = 60
    public static let cardCountPerColor = 10
    public static let cubeCount = 30
    public static let cubeCountPerColor = 5
    // building card count
    public static let shipCardsCount = 14
    public static let officeCardsCount = 2
    public static let dockerCardsCount = 2
    public static let tradeAgreementCardsCount = 2
    // max hand size
    public static let maxHandSize = 6
    public static let marketplaceSize = 6
}

enum GoodsCube: String, CaseIterable, Codable, CustomStringConvertible {
    case sugar, indigo, spices, tea, silk, lumber

    var description: String {
        switch self {
        case .sugar: return "Sugar"
        case .indigo: return "Indigo"
        case .spices: return "Spices"
        case .tea: return "Tea"
        case .silk: return "Silk"
        case .lumber: return "Lumber"
        }
    }

    // map the goods cube to an asset resource
    func resourceImageName() -> String {
        switch self {
        case .sugar: return "crate-white"
        case .indigo: return "crate-blue"
        case .spices: return "crate-red"
        case .tea: return "crate-green"
        case .silk: return "crate-purple"
        case .lumber: return "crate-brown"
        }
    }
}


extension GoodsCube {
    static func makePile(count: Int) -> [GoodsCube] {
        GoodsCube.allCases.flatMap { color in
            Array(repeating: color, count: count)
        }
    }
}

struct BuildingDefinition: Equatable, Codable {
    let name: String
    let details: String
    let cost: Int
    let cubeCapacity: Int
    let cubeSlots: [GoodsCube]
    let quantity: Int

    init(name: String, details: String, cost: Int, cubeCapacity: Int = 0, cubeSlots: [GoodsCube] = [], quantity: Int = 1) {
        self.name = name
        self.details = details
        self.cost = cost
        self.cubeCapacity = cubeCapacity
        self.cubeSlots = cubeSlots
        self.quantity = quantity
    }
}

extension BuildingDefinition {
    static func makeDeck() -> [BuildingDefinition] {
        [
            BuildingDefinition(name: "Ship", details: "Each ship can hold 1 goods cube. After purchasing a ship, the player immediately takes a goods cube and places it on the ship.", cost: 10, cubeCapacity: 1, cubeSlots: [], quantity: GameConstants.shipCardsCount),            
            BuildingDefinition(name: "Office", details: "Draw 1 goods card at the end of Phase 2, regardless of the action taken.", cost: 8, quantity: GameConstants.officeCardsCount),
            BuildingDefinition(name: "Docker", details: "Allows the player to exchange an extra goods cube during Phase 1.", cost: 12, quantity: GameConstants.dockerCardsCount),
            BuildingDefinition(name: "Trade agreement", details: "Receive 2 additional coins when you deliver goods.", cost: 11, quantity: GameConstants.tradeAgreementCardsCount)
        ].flatMap { definition in
            Array(repeating: definition, count: definition.quantity)
        }
    }
}

struct GameSetup {
    let drawPile: [GoodsCube]
    let cubePile: [GoodsCube]
    let marketplace: [GoodsCube]
}

// Main game model
class MerchantsGame {
    var currentState: GameState = .setup
    var buildings: [BuildingDefinition] = []
    var drawPile: [GoodsCube] // draw pile of good cards
    var cubePile: [GoodsCube] // draw pile of cubes
    var marketplace: [GoodsCube] = [] // cards marketplace is always 6 cards, filled in setup
    private var turnOrderManager: TurnOrderManager<Player>?
    var players: [Player] { turnOrderManager?.allPlayers ?? [] }
    var activePlayer: Player? { turnOrderManager?.currentPlayer }
    var currentTurnPhase: TurnPhase = .phase1
    
    init(buildings: [BuildingDefinition], drawPile: [GoodsCube], cubePile: [GoodsCube], players: [Player], marketplace: [GoodsCube] = []) {
        self.buildings = buildings
        self.drawPile = drawPile
        self.cubePile = cubePile
        self.turnOrderManager = players.isEmpty ? nil : TurnOrderManager(players: players)
        self.marketplace = marketplace
    }

    func newGame(players: [Player]) {
        guard players.count > 0 else { print("Not enough players"); return }

        self.turnOrderManager = TurnOrderManager(players: players)
        let setup = makeDefaultGameSetup()
        self.drawPile = setup.drawPile
        self.cubePile = setup.cubePile
        self.marketplace.removeAll()
        self.marketplace = setup.marketplace

        resetPlayersForNewGame()
        dealInitialHands()
        assignStartingShips()
        fillMarketplace(with: GameConstants.marketplaceSize)
        currentState = .phase1
        currentTurnPhase = .phase1
    }

    @discardableResult
    func advanceTurn() -> Player? {
        turnOrderManager?.advance()
    }

    func makeDefaultGameSetup() -> GameSetup {
        var drawPile = GoodsCube.makePile(count: GameConstants.cardCountPerColor)
        drawPile.shuffle()

        var cubePile = GoodsCube.makePile(count: GameConstants.cubeCountPerColor)
        cubePile.shuffle()

        return GameSetup(drawPile: drawPile, cubePile: cubePile, marketplace: [])
    }

    func resetPlayersForNewGame() {
        for player in self.players {
            player.hand = []
            player.tableau = []
            player.cubes = []
            player.coins = 0
        }
    }

    func dealInitialHands() {
        for player in self.players {
            let cardsToDraw = min(3, drawPile.count)
            let drawnCards = Array(drawPile.prefix(cardsToDraw))
            player.hand.append(contentsOf: drawnCards)
            drawPile.removeFirst(cardsToDraw)
        }
    }

    func assignStartingShips() {
        for player in self.players {
            let shipCards = buildings.filter { $0.name == "Ship" }.prefix(2)
            for ship in shipCards {
                if let index = buildings.firstIndex(of: ship) {
                    buildings.remove(at: index)
                }
                player.tableau.append(ship)
            }
        }
    }

    func fillMarketplace(with count: Int = 6) {
        let cardsToDraw = min(count, drawPile.count)
        let drawnCards = Array(drawPile.prefix(cardsToDraw))
        marketplace.append(contentsOf: drawnCards)
        drawPile.removeFirst(cardsToDraw)
    }
}
