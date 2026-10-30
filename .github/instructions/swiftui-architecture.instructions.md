---
description: "Use when planning or changing Swift and SwiftUI architecture, navigation, screens, or views in this app."
applyTo: "Merchants/Merchants/**/*.swift"
---

# SwiftUI Architecture

- Plan screen responsibilities and navigation before implementing UI changes.
- Keep screen containers focused on composition and navigation; do not put unrelated view interfaces in one screen view.
- Give each use case a focused SwiftUI view and a matching filename, such as `GameMarketplaceView.swift` containing `GameMarketplaceView`.
- Split complex screens into small, consistently named view components. Keep state and game rules in the session or model, not in presentation-only views.
- Use a navigation coordinator and explicit routes for moving between screens. Present gameplay in the dedicated game screen and its focused child views.
- After changing a flow, verify its screen transitions, game-rule ordering, and relevant player state changes with focused tests.
