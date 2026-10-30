//
//  PlayerAvatarView.swift
//  Merchants
//
//  Created by Amarjit on 01/08/2026.
//

import SwiftUI

// Displays a single player avatar

enum AvatarResource: String, CaseIterable {
    case avt1 = "avt-1"
    case avt2 = "avt-2"
    case avt3 = "avt-3"
    case avt4 = "avt-4"
    case avt5 = "avt-5"
}

struct PlayerAvatarView: View {
    let avatar: AvatarResource
    var isSelected = false

    var body: some View {
        Image(avatar.rawValue)
            .resizable()
            .scaledToFill()
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
            }
    }
}

#Preview {
    HStack(spacing: 16) {
        PlayerAvatarView(avatar: .avt1)
        PlayerAvatarView(avatar: .avt2, isSelected: true)
    }
}
