//
//  GameMessageView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI
import GameMessagesKit

// MARK: - Kind styling

extension GameMessageKind {
    /// Accent colour for each message kind
    var color: Color {
        switch self {
        case .info:    return .cyan
        case .success: return .green
        case .warning: return .orange
        case .error:   return .red
        @unknown default: return .gray
        }
    }

    /// SF Symbol shown for each message kind
    var systemImage: String {
        switch self {
        case .info:    return "info.circle.fill"
        case .success: return "checkmark.seal.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error:   return "xmark.octagon.fill"
        @unknown default: return "questionmark.circle.fill"
        }
    }
}


struct GameMessageView: View {
    let message: GameMessage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: message.kind.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(message.kind.color)
                .frame(width: 36, height: 36)
                .background(message.kind.color.opacity(0.2), in: Circle())
                .accessibilityHidden(true)

            Text(message.text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(message.kind.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(message.kind.color.opacity(0.5), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(message.kind.accessibilityPrefix): \(message.text)")
    }
}


/*
// MARK: - Single message

struct GameMessageView: View {
    let message: GameMessage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: message.kind.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(message.kind.color)
                .frame(width: 36, height: 36)
                .background(message.kind.color.opacity(0.2), in: Circle())

            Text(message.text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(message.kind.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(message.kind.color.opacity(0.5), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        GameMessageView(message: GameMessage(kind: .info, text: "New quest available in the village"))
        GameMessageView(message: GameMessage(kind: .success, text: "Level 4 complete! +250 XP"))
        GameMessageView(message: GameMessage(kind: .warning, text: "Health is running low"))
        GameMessageView(message: GameMessage(kind: .error, text: "Save failed. Check your connection."))
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
*/
