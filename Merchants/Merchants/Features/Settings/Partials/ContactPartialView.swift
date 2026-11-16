//
//  ContactPartialView.swift
//  Merchants
//
//  Created by Amarjit on 16/11/2026.
//

import SwiftUI

// Partial view: To be displayed in the settings view
struct ContactPartialView: View {
    var body: some View {
        VStack {
            Text("Hi I'm Amo and I make fun apps that I hope you'll love.")
            Text("I'm an independent developer & it would help me so much if you could share my app with friends & family as well as leave a review")
        }
        // Form list with icons
        Form {
            Label("Rate in App store", systemImage: "heart.fill")
            Label("Send Feedback", systemImage: "bubble.fill")
            Label("Share <appname> with friends", systemImage: "bubble.fill")
            Label("Credits & Attribution", systemImage: "heart.fill")
            Label("Name", systemImage: "heart.fill")
        }
    }
}

#Preview {
    ContactPartialView()
}
