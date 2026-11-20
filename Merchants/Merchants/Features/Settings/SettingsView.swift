//
//  SettingsView.swift
//  Merchants
//
//  Created by Amarjit on 16/11/2026.
//
import GameSettingsKit
import Foundation
import SwiftUI

// Settings - list of in game settings
// Structure:
// - Unlock everythingRemove ads big chunky button area
// - Sound/Music preferences
// - Contact with hero section, text
// - My other apps list with thumbnails

import StoreKit

// MARK: - Settings screen

struct SettingsView: View {
    @State private var model = PreferencesModel()
    @Environment(\.dismiss) private var dismiss

    private let soundAndMusicRows: [SettingRow] = [
        SettingRow(setting: .sound, title: "Card & dice sounds", icon: "speaker.wave.2.fill"),
        SettingRow(setting: .music, title: "Game music", icon: "music.note"),
        SettingRow(setting: .haptic, title: "Haptics", icon: "iphone.radiowaves.left.and.right"),
        SettingRow(setting: .darkMode, title: "Dark mode", icon: "moon.fill"),
        SettingRow(setting: .showHints, title: "Show hints", icon: "lightbulb.fill")
    ]

    var body: some View {
        NavigationStack {
            List {
                // Big chunky unlock banner
                Section {
                    UnlockBanner {
                        // Present your paywall / IAP sheet here
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                // Sound and music toggles
                Section("SOUND & MUSIC") {
                    ForEach(soundAndMusicRows) { row in
                        Toggle(isOn: model.binding(for: row.setting)) {
                            Label(row.title, systemImage: row.icon)
                        }
                    }
                }

                // Contact / hero section
                Section("CONTACT & OTHER") {
                    ContactCard(
                        avatarImageName: "amo-avatar",
                        headline: "Hi from Amo 👋🏾",
                        message: """
                        Hi I'm Amo and I try to make fun turn based games and useful apps that I hope you'll enjoy.
                        I'm an solo developer and it would help me so much \
                        if you could share my app with friends & family as well as \
                        leave a review on the App Store. Thank you ❤️
                        """,
                        appStoreID: "@{appstore.ID}",
                        feedbackEmail: "@{email.address}",
                        shareURL: URL(string: "https://apps.apple.com/app/idYOUR_APP_STORE_ID")!,
                        shareMessage: "Check out @{app.name}!"
                    )
                    .listRowInsets(EdgeInsets())
                }

                // My other apps
                Section("MY OTHER APPS") {
                    OtherAppsList(apps: [
                        OtherApp(
                            name: "TITLE",
                            tagline: "TAGLINE",
                            iconImageName: "portfolio-icon-app",
                            url: URL(string: "URI")!
                        )
                    ])
                }

                Section {
                    NavigationLink {
                        CreditsView()
                    } label: {
                        Label("Credits & Attribution", systemImage: "heart.circle")
                    }
                    Label("Privacy Policy")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Settings row model

struct SettingRow: Identifiable {
    let setting: Setting
    let title: LocalizedStringKey
    let icon: String

    var id: Setting { setting }
}

// MARK: - Unlock banner

struct UnlockBanner: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "crown.fill")
                    .font(.title)
                    .symbolRenderingMode(.hierarchical)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlock Everything")
                        .font(.title3.bold())
                    Text("No ads, ever.")
                        .font(.subheadline)
                        .opacity(0.85)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.headline)
                    .opacity(0.8)
            }
            .foregroundStyle(.white)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [.indigo, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Contact card

struct ContactCard: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    let avatarImageName: String
    let headline: LocalizedStringKey
    let message: String
    let appStoreID: String
    let feedbackEmail: String
    let shareURL: URL
    let shareMessage: String

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 16) {
                Image(avatarImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())

                Text(headline)
                    .font(.title2.bold())

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Divider()

            VStack(spacing: 0) {
                actionRow("Rate in App Store", systemImage: "star.bubble") {
                    requestReview()
                }
                Divider().padding(.leading, 52)

                actionRow("Send Feedback", systemImage: "bubble.left.and.text.bubble.right") {
                    sendEmail(subject: "Feedback")
                }
                Divider().padding(.leading, 52)

                /*
                actionRow("Send Me An Email", systemImage: "envelope") {
                    sendEmail(subject: "Hello")
                }
                Divider().padding(.leading, 52)
                */
                
                ShareLink(
                    item: shareURL,
                    message: Text(shareMessage)
                ) {
                    Label("Share with Friends!", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 8)
        }
    }

    private func actionRow(
        _ title: LocalizedStringKey,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sendEmail(subject: String) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = feedbackEmail
        components.queryItems = [URLQueryItem(name: "subject", value: subject)]

        if let url = components.url {
            openURL(url)
        }
    }
}

// MARK: - Other apps

struct OtherApp: Identifiable {
    let id = UUID()
    let name: String
    let tagline: String
    let iconImageName: String
    let url: URL
}

struct OtherAppsList: View {
    let apps: [OtherApp]

    var body: some View {
        ForEach(apps) { app in
            Link(destination: app.url) {
                HStack(spacing: 12) {
                    Image(app.iconImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(app.tagline)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Placeholder

struct CreditsView: View {
    var body: some View {
        List {
            Text("Credits go here")
        }
        .navigationTitle("Credits & Attribution")
    }
}

#Preview {
    SettingsView()
}
