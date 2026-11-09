public enum TurnFlowError: Error, Equatable, Sendable {
    case invalidSeating
    case invalidDraftPosition
    case notYourTurn
    case wrongPhase
    case phaseAlreadyCompleted
    case baseActionRequired
    case baseActionAlreadyTaken
    case shipAlreadyExchangedThisPhase
    case shipAddedThisTurn
    case noExtraExchangeAvailable
    case cannotDrawMustDeliver
    case skipOnlyWhenDeckEmpty
    case gameNotStarted
    case gameFinished
    case invalidProgress
}
