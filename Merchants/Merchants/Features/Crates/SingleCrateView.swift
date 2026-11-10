//
//  CubeView.swift
//  Merchants
//

import SwiftUI

// Display a single crate asset resource image
// upon provided string value
// Should fit the bounding box it is provided
// Should be resizable

struct SingleCrateView: View {
    let resourceImage: String
    var body: some View {
        Image(resourceImage)
    }
}

#Preview {
    SingleCrateView(resourceImage: "crate-red")
}
