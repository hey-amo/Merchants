//
//  SingleCrateView.swift
//  Merchants
//

import SwiftUI

// Display a single crate asset resource image, scaled to fit the space it is given.
struct SingleCrateView: View {
    let resourceImage: String

    var body: some View {
        Image(resourceImage)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
    }
}

#Preview {
    SingleCrateView(resourceImage: "crate-spice")
        .frame(width: 80, height: 80)
}
