//
//  CaptainAvatarImg.swift
//  Merchants
//

import SwiftUI

/// Shows a single cell from a horizontal sprite sheet asset.
/// Cropping is proportional, so the 1x/2x/3x variants all work.
struct CaptainAvatarImg: View {
    let name: String
    let count: Int
    let index: Int

    var body: some View {
        let safeIndex = min(max(index, 0), count - 1)
        let sheet = Self.sheetSize(named: name)
        let cellAspect = sheet.height > 0 ? (sheet.width / CGFloat(count)) / sheet.height : 1

        Color.clear
            .aspectRatio(cellAspect, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    Image(name)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: geo.size.width * CGFloat(count), height: geo.size.height)
                        .offset(x: -geo.size.width * CGFloat(safeIndex))
                }
            }
            .clipped()
    }

    private static func sheetSize(named name: String) -> CGSize {
        #if canImport(UIKit)
        return UIImage(named: name)?.size ?? .zero
        #elseif canImport(AppKit)
        return NSImage(named: name)?.size ?? .zero
        #endif
    }
}

#Preview {
    HStack {
        ForEach(0..<5) { CaptainAvatarImg(name: "captains", count: 5, index: $0).frame(height: 60) }
    }
}
