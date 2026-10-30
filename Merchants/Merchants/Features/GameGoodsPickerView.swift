import SwiftUI

struct GameGoodsPickerView: View {
    let session: GameSession
    @Binding var selection: GoodsCube?
    var excluding: GoodsCube? = nil
    var availableInHand: [GoodsCube]? = nil
    var requiresCubeSupply = true

    var body: some View {
        let _ = session.revision

        HStack {
            ForEach(availableColors, id: \.self) { color in
                Button {
                    selection = color
                } label: {
                    VStack(spacing: 2) {
                        CubeView(cube: color, size: 38)
                        Text(color.description)
                            .font(.caption2)
                    }
                    .padding(4)
                    .background(
                        selection == color
                            ? Color.accentColor.opacity(0.2)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == color ? .isSelected : [])
            }
        }
    }

    private var availableColors: [GoodsCube] {
        GoodsCube.allCases.filter { color in
            color != excluding &&
            (!requiresCubeSupply || session.availableCubeCount(for: color) > 0) &&
            (availableInHand?.contains(color) ?? true)
        }
    }
}
