import Foundation

struct WinnerPlayerModel: Identifiable {
    let id = UUID()
    let name: String
    let coins: Int
    var isHuman: Bool = false
    /// 0-based captain in the `captains` sprite sheet.
    var avatarIndex: Int = 0

    var kindEmoji: String { isHuman ? "🧑" : "🤖" }
    var kindLabel: String { isHuman ? "Human" : "Bot" }
}
