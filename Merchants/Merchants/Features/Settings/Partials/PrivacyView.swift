////
//  PrivacyView.swift
//  Merchants
//
//  Created by AD on 20/11/2026.
//



import SwiftUI
import UserNotifications

// MARK: - Data model

enum PrivacyHandling {
    case onDevice
    case notCollected
    case thirdParty
    case optional

    var systemImage: String {
        switch self {
        case .onDevice: "iphone"
        case .notCollected: "checkmark.circle.fill"
        case .thirdParty: "person.2.circle.fill"
        case .optional: "bell.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .onDevice: .blue
        case .notCollected: .green
        case .thirdParty: .orange
        case .optional: .gray
        }
    }
}

struct PrivacyDataItem: Identifiable {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let handling: PrivacyHandling

    var id: String { "\(title)" }
}


// MARK: - Privacy view

struct PrivacyView: View {
    @Environment(\.openURL) private var openURL
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    // Replace with your hosted privacy policy URL
    private let policyURL = URL(string: "https://yourdomain.com/privacy")!

    private let dataItems: [PrivacyDataItem] = [
        PrivacyDataItem(
            title: "Game progress and settings",
            detail: "Saved only on this device. We never receive it.",
            handling: .onDevice
        ),
        PrivacyDataItem(
            title: "Account or sign-in",
            detail: "Not required. You can play without creating an account.",
            handling: .notCollected
        ),
        PrivacyDataItem(
            title: "Personal information",
            detail: "We don't ask for your name, email address, or contacts.",
            handling: .notCollected
        ),
        PrivacyDataItem(
            title: "Purchases",
            detail: "Handled by Apple. We never see your payment details.",
            handling: .thirdParty
        ),
        PrivacyDataItem(
            title: "Advertising",
            detail: "Ad platforms may use limited data to show contextual ads, under their own privacy policies.",
            handling: .thirdParty
        ),
        PrivacyDataItem(
            title: "Notifications",
            detail: "Optional and off by default. You choose whether to allow them.",
            handling: .optional
        )
    ]

    var body: some View {
        List {
            Section("ABOUT") {
                Text("Merchants is a local game. Your progress and settings stay on your device, and we don't collect personal information.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Section("HOW YOUR DATA IS USED") {
                ForEach(dataItems) { item in
                    PrivacyRow(item: item)
                }
            }

            Section("PERMISSIONS") {
                LabeledContent {
                    Text(notificationStatusText)
                        .foregroundStyle(.secondary)
                } label: {
                    Label("Notifications", systemImage: "bell.badge")
                }

                LabeledContent {
                    Text("Not required")
                        .foregroundStyle(.secondary)
                } label: {
                    Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
                }

                Button {
                    openAppSettings()
                } label: {
                    Label("Manage in Settings", systemImage: "gearshape")
                }
            }

            Section {
                Button {
                    openURL(policyURL)
                } label: {
                    Label("Read full privacy", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Privacy")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationStatus = settings.authorizationStatus
        }
    }

    private var notificationStatusText: LocalizedStringKey {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: "On"
        case .denied: "Off"
        case .notDetermined: "Not asked"
        @unknown default: "Unknown"
        }
    }

    private func openAppSettings() {
        // Equivalent to UIApplication.openSettingsURLString on iOS
        if let url = URL(string: "app-settings:") {
            openURL(url)
        }
    }
}
// MARK: - Row

struct PrivacyRow: View {
    let item: PrivacyDataItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.handling.systemImage)
                .font(.title3)
                .foregroundStyle(item.handling.tint)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.headline)
                Text(item.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrivacyView()
    }
}
