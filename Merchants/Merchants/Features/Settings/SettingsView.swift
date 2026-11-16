//
//  SettingsView.swift
//  Merchants
//
//  Created by Amarjit on 16/11/2026.
//
import GameSettingsPK
import Foundation
import SwiftUI

// Settings - list of in game settings
// Structure:
// - Remove ads big chunky button area
// - Sound/Music preferences
// - About
// - Contact
// - My other apps

struct SettingsView: View {
    @State private var model = PreferencesModel()
    @Environment(\.dismiss) private var dismiss

    private let rows: [(setting: Setting, title: LocalizedStringKey, icon: String)] = [
        (.sound, "Sound effects", "speaker.wave.2.fill"),
        (.music, "Music", "music.note"),
        (.haptic, "Haptics", "iphone.radiowaves.left.and.right"),
        (.darkMode, "Dark mode", "moon.fill"),
        (.showHints, "Show hints", "lightbulb.fill")
    ]

    var body: some View {
        NavigationStack {
            Form {
                ForEach(rows, id: \.setting) { row in
                    Toggle(isOn: model.binding(for: row.setting)) {
                        Label(row.title, systemImage: row.icon)
                    }
                }
            }
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
        .presentationDetents([.medium])
    }
}

#Preview {
    SettingsView()
}
