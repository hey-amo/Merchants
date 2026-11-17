//
//  PreferenceView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI
import GameSettingsKit

// Partial view: for managing preferences like sound, music, haptics, dark mode, hints, tutorials, notifications

@MainActor
@Observable
final class PreferencesModel {
    private(set) var enabled: Set<Setting>
    private let settings: GameSettings

    init(enabled: Set<Setting> = [.sound, .music, .haptic, .showHints]) {
        self.enabled = enabled
        settings = GameSettings(enabledSettings: enabled)
    }

    func binding(for setting: Setting) -> Binding<Bool> {
        Binding(
            get: { self.enabled.contains(setting) },
            set: { isOn in
                if isOn { self.enabled.insert(setting) } else { self.enabled.remove(setting) }
                Task { await self.settings.setEnabled(isOn, for: setting) }
            }
        )
    }
}

struct PreferencesView: View {
    @State private var model = PreferencesModel()
    
    private let rows: [(setting: Setting, title: LocalizedStringKey, icon: String)] = [
        (.sound, "Sound effects", "speaker.wave.2.fill"),
        (.music, "Music", "music.note"),
        (.haptic, "Haptics", "iphone.radiowaves.left.and.right"),
        (.darkMode, "Dark mode", "moon.fill"),
        (.showHints, "Show hints", "lightbulb.fill")
    ]

    var body: some View {
        Form {
            ForEach(rows, id: \.setting) { row in
                Toggle(isOn: model.binding(for: row.setting)) {
                    Label(row.title, systemImage: row.icon)
                }
            }
        }
    }
}

#Preview {
    PreferencesView()
}
