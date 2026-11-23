//
//  MainMenuView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI

/// Root menu. The sea-blue field is the game's brand colour (RGB 98, 222, 253).
struct MainMenuView: View {
    /// Enable once a saved game can actually be resumed.
    var canContinueGame = false

    @State private var path = NavigationPath()
    @State private var showsSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                MenuBackground()

                VStack(spacing: 0) {
                    Spacer(minLength: 12)

                    header
                        .padding(.bottom, 36)

                    VStack(spacing: 16) {
                        menuButton(
                            "Continue game",
                            route: .continueGame,
                            isEnabled: canContinueGame,
                            isPrimary: canContinueGame
                        )
                        menuButton("New game", route: .newGame, isPrimary: !canContinueGame)
                        menuButton("Leaderboard", route: .leaderboard)
                    }

                    Spacer(minLength: 28)

                    utilityRow
                        .padding(.bottom, 16)

                    Text("V\(appVersion)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.black.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Version \(appVersion)")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 8)
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: MainMenuRoute.self) { route in
                destination(for: route)
            }
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView()
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            Image("ship-nobg")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(maxWidth: 168, maxHeight: 112)
                .accessibilityHidden(true)

            Text("Merchants")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.black)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity)
    }

    private var utilityRow: some View {
        HStack(spacing: 16) {
            Button {
                showsSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.black)
                    .frame(width: 56, height: 56)
                    .background(MenuBackground.buttonFill, in: Circle())
            }
            .buttonStyle(MenuPressStyle())
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens sound, music, and other preferences")

            Button {
                path.append(MainMenuRoute.about)
            } label: {
                Text("About")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 28)
                    .frame(minHeight: 56)
                    .background(MenuBackground.buttonFill, in: Capsule())
            }
            .buttonStyle(MenuPressStyle())
            .accessibilityHint("About this game")

            Spacer(minLength: 0)
        }
    }

    private func menuButton(
        _ title: String,
        route: MainMenuRoute,
        isEnabled: Bool = true,
        isPrimary: Bool = false
    ) -> some View {
        Button {
            path.append(route)
        } label: {
            MainMenuLabel(title: title, isEnabled: isEnabled)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(MenuBackground.buttonFill(isEnabled: isEnabled, isPrimary: isPrimary), in: Capsule())
        }
        .buttonStyle(MenuPressStyle())
        .disabled(!isEnabled)
        .accessibilityHint(hint(for: route, isEnabled: isEnabled))
    }

    @ViewBuilder
    private func destination(for route: MainMenuRoute) -> some View {
        switch route {
        case .newGame:
            GameSetupView()
        case .continueGame:
            ContentUnavailableView(
                "Ready to resume",
                systemImage: "ferry",
                description: Text("Your last game will open here.")
            )
            .navigationTitle("Continue")
            .navigationBarTitleDisplayMode(.inline)
        case .leaderboard:
            ContentUnavailableView(
                "No scores yet",
                systemImage: "trophy",
                description: Text("Finish a game and the standings will show up here.")
            )
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
        case .about:
            AboutMerchantsView()
        }
    }

    private func hint(for route: MainMenuRoute, isEnabled: Bool) -> String {
        switch route {
        case .continueGame:
            isEnabled ? "Resume your last game" : "No saved game to resume"
        case .newGame:
            "Set up a new game"
        case .leaderboard:
            "See finished games"
        case .about:
            "About this game"
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

private enum MainMenuRoute: Hashable {
    case continueGame
    case newGame
    case leaderboard
    case about
}

private struct MainMenuLabel: View {
    let title: String
    var isEnabled = true

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
            Image(systemName: "chevron.right")
                .font(.body.weight(.bold))
                .accessibilityHidden(true)
        }
        .font(.title3.weight(.semibold))
        .foregroundStyle(.black.opacity(isEnabled ? 1 : 0.38))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
    }
}

private struct MenuBackground: View {
    /// RGB {98, 222, 253}.
    static let color = Color(red: 98 / 255, green: 222 / 255, blue: 253 / 255)

    static let buttonFill = Color.white.opacity(0.55)

    static func buttonFill(isEnabled: Bool, isPrimary: Bool = false) -> Color {
        if !isEnabled { return Color.white.opacity(0.32) }
        return Color.white.opacity(isPrimary ? 0.82 : 0.55)
    }

    var body: some View {
        Self.color.ignoresSafeArea()
    }
}

/// Press feedback that stays still when Reduce Motion is on.
private struct MenuPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed && !reduceMotion ? 0.72 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct AboutMerchantsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Play as a merchant in the age of sail. Deliver cargo to the market, earn coins, and finish with the most.")
                    .font(.body)

                Text("This is an unofficial version of Reiner Knizia’s Merchants, adapted for play on a phone.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("No saved game") {
    MainMenuView()
}

#Preview("Saved game") {
    MainMenuView(canContinueGame: true)
}
