//
//  GameMessageListView.swift
//  Merchants
//
//  Created by Amarjit on 09/11/2026.
//

import SwiftUI
import GameMessagesKit
import MerchantsGame
import Observation

// Show in-game messages in a lazy list
// - can clear messages
// - it only holds a max of 100 messages, and overwrites the oldest messages
// - may need to be in a uitableview if its too memory intensive
// - needs to be lazy loading, memory-safe
// Uses: GameMessageView

struct GameMessage: Identifiable, Hashable {
    let id = UUID()
    let kind: GameMessageKind
    let text: String
}


// MARK: Message store

@MainActor
@Observable
final class GameMessageStore {
    static let capacity = 100
    
    /// Oldest first, newest last. Capped at `capacity`.
    private(set) var messages: [GameMessage] = []
    
    func append(_ message: GameMessage) {
        messages.append(message)
        
        // Drop the oldest messages so we never exceed the cap.
        let overflow = messages.count - Self.capacity
        if overflow > 0 {
            messages.removeFirst(overflow)
        }
    }
    
    func clear() {
        // Keeps the reserved buffer, so refilling doesn't reallocate.
        messages.removeAll(keepingCapacity: true)
    }
}

// MARK: Message List View

struct GameMessageListView: View {
    let store: GameMessageStore
    
    var body: some View {
        Group {
            if store.messages.isEmpty {
                ContentUnavailableView {
                    Label("No messages yet", systemImage: "tray")
                } description: {
                    Text("Game messages will appear here.")
                }
            } else {
                messageList
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear", role: .destructive) {
                    store.clear()
                }
                .disabled(store.messages.isEmpty)
            }
        }
    }
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(store.messages) { message in
                    GameMessageView(message: message)
                        .id(message.id)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onChange(of: store.messages.last?.id) { _, newestID in
                guard let newestID else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(newestID, anchor: .bottom)
                }
            }
        }
    }

    
    
}


// MARK: Preview

#Preview("Game message list") {
    let store = GameMessageStore()

    // Seed sample messages covering every kind
    let samples: [GameMessage] = [
        GameMessage(kind: .info, text: "Welcome to the game"),
        GameMessage(kind: .success, text: "Quest complete: The Lost Key"),
        GameMessage(kind: .warning, text: "Your health is running low"),
        GameMessage(kind: .error, text: "Could not save progress"),
        GameMessage(kind: .info, text: "New area discovered: Ashen Marsh"),
        GameMessage(kind: .success, text: "Level up! You reached level 5")
    ]
    samples.forEach { store.append($0) }

    return NavigationStack {
        GameMessageListView(store: store)
            .navigationTitle("Log")
            .background(Color.black)
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty state") {
    NavigationStack {
        GameMessageListView(store: GameMessageStore())
            .navigationTitle("Log")
            .background(Color.black)
    }
    .preferredColorScheme(.dark)
}

#Preview("Overflow past capacity") {
    let store = GameMessageStore()

    // Append more than the cap to confirm the oldest are dropped
    for index in 1...(GameMessageStore.capacity + 20) {
        store.append(GameMessage(kind: .info, text: "Message \(index)"))
    }

    return NavigationStack {
        GameMessageListView(store: store)
            .navigationTitle("Log")
            .background(Color.black)
    }
    .preferredColorScheme(.dark)
}
