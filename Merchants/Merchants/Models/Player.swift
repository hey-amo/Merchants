//
//  Player.swift
//  Merchants
//
//  Created by Amarjit on 31/07/2026.
//

import Foundation
import GameplayKit


class Player: NSObject, GKGameModelPlayer, Codable {
    var playerId: Int
    var coins: Int
    var hand: [GoodsCube] // hand of good cards
    var tableau: [BuildingDefinition] = [] // buildings owned by the player
    var cubes: [GoodsCube] // cubes in possession
    var isAI: Bool
    var isStartPlayer: Bool = false
    var state: PlayerState
    var avatar: String
    private var maxHandSize: Int = GameConstants.maxHandSize
    
    init(playerId: Int, coins: Int, hand: [GoodsCube] = [], tableau: [BuildingDefinition] = [], 
        cubes: [GoodsCube] = [], isAI: Bool = false, avatar: String = "", isStartPlayer: Bool = false,
        state: PlayerState = .idle) {
        self.playerId = playerId
        self.coins = coins
        self.hand = hand
        self.tableau = tableau
        self.cubes = cubes
        self.isAI = isAI
        self.avatar = avatar
        self.isStartPlayer = isStartPlayer
        self.state = state
    }



    func copy(with zone: NSZone? = nil) -> Any {
        return Player(playerId: playerId, coins: coins, hand: hand, tableau: tableau, cubes: cubes, 
            isAI: isAI, avatar: avatar, isStartPlayer: isStartPlayer, state: state)
    }
}

extension Player: TurnOrderPlayer {
    var id: Int { playerId }
}

extension Player: CoinUpdaterDelegate {
    func updateCoins(amount: Int) throws {
        self.coins += amount
    }
}

extension Player: HandUpdaterDelegate {
    func updateHand(with cubes: [GoodsCube]) throws {
        guard hand.count + cubes.count <= maxHandSize else {
            //print("Cannot add card to hand: exceeds maximum hand size.")
            throw HandErrorType.reachedMaxHandSize
        }
        hand.append(contentsOf: cubes)
    }
}
