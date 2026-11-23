//
//  RivalQuickView.swift
//  Merchants
//
//  Created by AD on 23/11/2026.
//

import SwiftUI
import MerchantsGame

struct RivalQuickView: View {
    var body: some View {
        SlideCard(title: "Rivals", systemImage: "person.2.fill") {
            Text("Hello world")
            /*
            VStack(alignment: .leading, spacing: 10) {
                ForEach(rivals, id: \.self) { name in
                    HStack {
                        Text(name)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "sailboat.fill")
                            .foregroundStyle(.secondary)
                        Text("Placeholder ships")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }*/
        }
    }
}

#Preview {
    RivalQuickView()
}
