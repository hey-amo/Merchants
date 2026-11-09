//
//  PlayerAvatarView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI

// Show the player's avatar in 2 states
// - active: `onTurn` state
// - idle: `idle` or waiting for their turn state
struct PlayerAvatarView: View {
    enum State {
        case onTurn
        case idle
    }

    /// 0-based position of the captain in the `captains` sprite sheet.
    var avatarIndex: Int = 0
    var state: State = .idle

    private var isActive: Bool { state == .onTurn }

    var body: some View {
        CaptainAvatarImg(name: "captains", count: 5, index: avatarIndex)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .saturation(isActive ? 1 : 0.4)
            .opacity(isActive ? 1 : 0.7)
/*            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isActive ? Color.cyan : Color.gray.opacity(0.6),
                                  lineWidth: isActive ? 4 : 2)
            }*/
            .shadow(color: isActive ? Color.cyan.opacity(0.8) : .clear, radius: 8)
            .scaleEffect(isActive ? 1.05 : 1)
            .animation(.easeInOut(duration: 0.2), value: state)
    }
}

#Preview("States") {
    HStack(spacing: 24) {
        PlayerAvatarView(avatarIndex: 1, state: .onTurn)
        PlayerAvatarView(avatarIndex: 1, state: .idle)
    }
    .padding()
    .frame(height: 140)
}
