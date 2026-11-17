//
//  GameHistoryLogView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI
import GameMessagesKit
import MerchantsGame

// Show in-game messages in a lazy list
// - can clear messages
// - it only holds a max of 100 messages, and overwrites the oldest messages
// - sorted to show the latest message first
// - may need to be in a uitableview if its too memory intensive
// - needs to be lazy loading, memory-safe
struct GameHistoryLogView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    GameHistoryLogView()
}
