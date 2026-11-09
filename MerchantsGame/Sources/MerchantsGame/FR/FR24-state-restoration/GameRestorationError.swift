import Foundation

public struct GameRestorationError: Error, LocalizedError, CustomStringConvertible {
    static let message = "Game error - corrupted data"
    public let underlyingError: any Error

    public var description: String { Self.message }
    public var errorDescription: String? { description }

    init(underlyingError: any Error) {
        self.underlyingError = underlyingError
    }
}
