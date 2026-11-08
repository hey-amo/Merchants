//
//  Treasury.swift
//  MerchantsPackage
//
//  Created by Amarjit on 08/11/2026.
//

// Simple add coins, subtract coins

public enum TreasuryAction {
    case add(_ funds: Int = 0)
    case subtract(_ funds: Int = 0)
}

public struct Treasury: Sendable {
    private var _coins: Int
    public var available: Int {
        get { return self._coins }
    }
}

extension Treasury {
    public func perform(_ action: TreasuryAction) {
        switch action {
        case .add(let amount):
            break
        case .subtract(let amount):
            break
        }
    }
    
    fileprivate mutating func add(_ amount: Int = 0) {
        guard amount > 0 else { return }
        self._coins += amount
    }
    
    fileprivate mutating func subtract(_ amount: Int = 0) {
        guard amount > 0 else { return }
        guard available >= amount else { return }
        self._coins -= amount
    }
}
