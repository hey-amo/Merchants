//
//  GoodType+Crate.swift
//  Merchants
//

import MerchantsGame
import Foundation

// Presentation mapping for goods: crate/goods-card artwork and display names.
extension GoodType {
    var crateImageName: String {
        switch self {
        case .sugar: "crate-sugar"
        case .indigo: "crate-indigo"
        case .spices: "crate-spice"
        case .tea: "crate-tea"
        case .silk: "crate-silk"
        case .lumber: "crate-lumber"
        }
    }

    var goodsImageName: String {
        switch self {
        case .sugar: "goods-sugar"
        case .indigo: "goods-indigo"
        case .spices: "goods-spice"
        case .tea: "goods-tea"
        case .silk: "goods-silk"
        case .lumber: "goods-lumber"
        }
    }

    var displayName: String {
        switch self {
        case .sugar: NSLocalizedString("Sugar", comment: "Good: Sugar")
        case .indigo: NSLocalizedString("Indigo", comment: "Good: Indigo")
        case .spices: NSLocalizedString("Spices", comment: "Good: Spices")
        case .tea: NSLocalizedString("Tea", comment: "Good: Tea")
        case .silk: NSLocalizedString("Silk", comment: "Good: Silk")
        case .lumber: NSLocalizedString("Lumber", comment: "Good: Lumber")
        }
    }
}
