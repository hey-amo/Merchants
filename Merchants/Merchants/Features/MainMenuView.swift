//
//  ContentView.swift
//  Merchants
//
//  Created by Amarjit on 29/06/2026.
//

import SwiftUI
//import SwiftData

// Make the play button bigger and chunkier

struct MainMenuView: View {
    @State private var navigation = NavigationHandler()

    var body: some View {
        NavigationStack(path: $navigation.path) {
            ZStack {
                Color(
                    red: 98.0 / 255.0,
                    green: 222.0 / 255.0,
                    blue: 253.0 / 255.0
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Merchants")
                        .font(.largeTitle.bold())
                    Text("Build 1.0").font(.subheadline)
                    Image("ship-nobg")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                    Button("Play") {
                        navigation.push(.playerSelection)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationDestination(for: Route.self, destination: destination(for:))
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .playerSelection:
            PlayerSelectScreen { playerCount in
                let players = (1...playerCount).map { playerID in
                    Player(
                        playerId: playerID,
                        coins: 0,
                        avatar: AvatarResource.allCases[playerID - 1].rawValue
                    )
                }
                navigation.push(.cubeSelection(GameSession(players: players)))
            }
        case .cubeSelection(let session):
            CubeSelectionScreen(session: session) {
                navigation.push(.game(session))
            }
        case .game(let session):
            GameCanvas(session: session) {
                navigation.push(.pause(session))
            } onGameOver: {
                navigation.push(.winner(session))
            }
        case .pause:
            PauseMenuScreen(
                onContinue: { navigation.pop() },
                onQuit: { navigation.popToRoot() }
            )
        case .winner(let session):
            WinnerScreenView(players: session.players) {
                navigation.popToRoot()
                navigation.push(.playerSelection)
            }
        }
    }
}

#Preview {
    MainMenuView()
}
