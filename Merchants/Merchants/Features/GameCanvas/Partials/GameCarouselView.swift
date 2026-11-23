// GameCarouselView

import SwiftUI
import MerchantsGame

// Carousel:
// - Crates in stock
// - MarketplaceView
// - RivalQuickView (Shows me what ships they have)

import SwiftUI
import Observation

// MARK: - Slides

enum CarouselSlide: Int, CaseIterable, Hashable, Identifiable {
    case crates
    case marketplace
    case rivals

    var id: Int { rawValue }

    /// 1-based number for display and demo buttons.
    var number: Int { rawValue + 1 }
}

// MARK: - Controller (injection hooks)

@MainActor
@Observable
final class CarouselController {
    /// The slide currently shown. Bound to the TabView.
    var selection: CarouselSlide = .crates

    /// The slide currently glowing, or nil when none is highlighted.
    private(set) var highlighted: CarouselSlide?

    private var clearHighlightTask: Task<Void, Never>?

    /// Moves to a slide. Pass `highlight: true` to also flash it.
    func show(_ slide: CarouselSlide, highlight: Bool = false) {
        withAnimation(.easeInOut(duration: 0.3)) {
            selection = slide
        }
        if highlight {
            flash(slide)
        }
    }

    /// Flashes a slide without moving to it.
    func flash(_ slide: CarouselSlide, duration: Duration = .seconds(1.5)) {
        clearHighlightTask?.cancel()
        highlighted = slide

        clearHighlightTask = Task {
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            highlighted = nil
        }
    }

    func next() {
        guard let index = CarouselSlide.allCases.firstIndex(of: selection),
              index + 1 < CarouselSlide.allCases.count else { return }
        show(CarouselSlide.allCases[index + 1])
    }

    func previous() {
        guard let index = CarouselSlide.allCases.firstIndex(of: selection),
              index > 0 else { return }
        show(CarouselSlide.allCases[index - 1])
    }
}

// MARK: - Carousel

struct GameCarouselView: View {
    @Bindable var controller: CarouselController
    
    var supply = CubeSupply()
        
    var body: some View {
        TabView(selection: $controller.selection) {
            slide(.crates) {
                CratesInSupplyView(
                    supply: supply
                )
            }
            slide(.marketplace) {
                MarketplaceView()
            }
            slide(.rivals) {
                // TBC: Should list all rivals in the game, their ships
                RivalQuickView()
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }

    private func slide<Content: View>(
        _ slide: CarouselSlide,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .highlighted(controller.highlighted == slide)
            .tag(slide)
            .accessibilityLabel("Slide \(slide.number) of \(CarouselSlide.allCases.count)")
    }
}

// MARK: - Highlight effect

private extension View {
    func highlighted(_ isOn: Bool) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.yellow, lineWidth: 3)
                    .opacity(isOn ? 1 : 0)
            )
            .shadow(color: .yellow.opacity(isOn ? 0.6 : 0), radius: isOn ? 12 : 0)
            .scaleEffect(isOn ? 1.02 : 1)
            .animation(.spring(duration: 0.35), value: isOn)
    }
}

// MARK: - Placeholder slides

/// Shared card chrome so every placeholder looks consistent.
struct SlideCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.primary)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}


// MARK: - Preview with demo controls

/*
private struct CarouselDemoHarness: View {
    @State private var controller = CarouselController()

    var body: some View {
        VStack(spacing: 20) {
            GameCarouselView(controller: controller)
                .frame(height: 280)

            VStack(spacing: 12) {
                Text("Move (swipe also works)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    ForEach(CarouselSlide.allCases) { slide in
                        Button("Slide \(slide.number)") {
                            controller.show(slide)
                        }
                    }
                }

                Text("Move and highlight")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("Previous") { controller.previous() }
                    Button("Next") { controller.next() }
                }

                Button("Flash Marketplace (no move)") {
                    controller.flash(.marketplace)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview("Carousel demo") {
    CarouselDemoHarness()
}
*/

#Preview("Carousel static") {
    GameCarouselView(controller: CarouselController())
        .frame(height: 285)
}
