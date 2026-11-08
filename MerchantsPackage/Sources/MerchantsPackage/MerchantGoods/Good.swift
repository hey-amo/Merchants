//
//  Good.swift
//  MerchantsPackage
//
//

import Foundation

public enum Good: Int, CaseIterable, Codable, Sendable {
    case sugar
    case indigo
    case spices
    case tea
    case silk
    case lumber
}

extension Good: CustomStringConvertible {
    public var description: String {
        switch self {
        case .sugar: return NSLocalizedString("Sugar", comment: "Good: Sugar")
        case .indigo: return NSLocalizedString("Indigo", comment: "Good: Indigo")
        case .spices: return NSLocalizedString("Spices", comment: "Good: Spices")
        case .tea: return NSLocalizedString("Tea", comment: "Good: Tea")
        case .silk: return NSLocalizedString("Silk", comment: "Good: Silk")
        case .lumber: return NSLocalizedString("Lumber", comment: "Good: Lumber")
        }
    }
}
