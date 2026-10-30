import Foundation
import Observation

enum Route: Hashable {
    case playerSelection
    case cubeSelection(GameSession)
    case game(GameSession)
    case pause(GameSession)
    case winner(GameSession)
}

@Observable
@MainActor
final class NavigationHandler {
    var path: [Route] = []

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popToRoot() {
        path.removeAll()
    }
}
