//
//  BotNames.swift
//  Merchants
//

import Foundation

// Single place to define bot display names. Swap this out later for themed names.
enum BotNames {
    /// 1-based bot number -> display name, e.g. "Bot #1".
    static func name(forBot number: Int) -> String {
        "Bot #\(number)"
    }
}
