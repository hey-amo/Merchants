import SwiftUI

struct GameMarketplaceView: View {
    let session: GameSession
    let selectedColor: GoodsCube?
    @Binding private var selectedSlots: Set<Int>
    private let isInteractive: Bool
    private let maxSelectionCount: Int

    init(
        session: GameSession,
        selectedColor: GoodsCube? = nil,
        selectedSlots: Binding<Set<Int>> = .constant([]),
        isInteractive: Bool = false,
        maxSelectionCount: Int = 0
    ) {
        self.session = session
        self.selectedColor = selectedColor
        _selectedSlots = selectedSlots
        self.isInteractive = isInteractive
        self.maxSelectionCount = maxSelectionCount
    }

    var body: some View {
        let _ = session.revision

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88))], spacing: 12) {
            ForEach(Array(session.game.marketplace.enumerated()), id: \.offset) { index, color in
                Button {
                    toggleSelection(at: index)
                } label: {
                    VStack(spacing: 4) {
                        CubeView(cube: color, size: 56)
                        Text("Space \(index + 1)")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(
                        selectedSlots.contains(index)
                            ? Color.accentColor.opacity(0.2)
                            : Color.secondary.opacity(0.08)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(!isInteractive || selectedColor == nil || session.phase2ActionCompleted)
                .accessibilityLabel("Marketplace space \(index + 1), \(color.description)")
                .accessibilityAddTraits(selectedSlots.contains(index) ? .isSelected : [])
            }
        }
    }

    private func toggleSelection(at index: Int) {
        guard isInteractive, selectedColor != nil, !session.phase2ActionCompleted else { return }
        if selectedSlots.contains(index) {
            selectedSlots.remove(index)
        } else if selectedSlots.count < maxSelectionCount {
            selectedSlots.insert(index)
        }
    }
}
