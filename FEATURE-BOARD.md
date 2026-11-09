# Feature requirements board

This board tracks [PRD section 7](PRD.md#7-feature-requirements). Treat
`PRD.md` as read-only; update this board as work progresses. Each card links
to the full requirement, including its acceptance criteria and tests.

## How to use

- **Integration branch:** `working-branch`. Create a micro-branch for each
  requirement from `working-branch`, push it once tests pass, and open a pull
  request targeting `working-branch`; do not create pull requests to `main`.
- **Planned:** not started or not yet assessed.
- **In progress:** started, but not complete against the PRD.
- **Ready to merge:** implemented and tested on a separate branch, but not yet
  present on `working-branch`.
- **Done:** present on `working-branch` and verified against the requirement.

Move cards between sections as their status changes. Record the branch and
remaining work for partially completed cards; do not mark a feature done solely
because a component or placeholder exists.

## In progress

- **[FR14 - Planning phase](PRD.md#fr14-planning-phase)** and
  **[FR15 - Trading phase](PRD.md#fr15-trading-phase)**
  Components are integrated with the engine on `working-branch` in PR #26;
  broader combined acceptance coverage and
  unified error localization remain.
- **[FR16 - Delivery scoring](PRD.md#fr16-delivery-scoring)**
  Pure scoring and engine payout integration are implemented and tested on
  `working-branch` in PR #26.
- **[FR17 - End game and winners](PRD.md#fr17-end-game-and-winners)**
  Rules and end-game handling are integrated on `working-branch` in PR #26.
- **[FR18 - Game actions and events](PRD.md#fr18-game-actions-and-events)** and
  **[FR19 - Game engine and player view](PRD.md#fr19-game-engine-and-player-view)**
  Core action pipeline, data-only player projection, legal actions, and
  deterministic setup are implemented on `working-branch` in PR #26,
  together with restoration and seeded replay/invariant coverage;
  full per-action acceptance and error localization remain outstanding.
- **[FR23 - Testing and replay](PRD.md#fr23-testing-and-replay)**
  PR #26 added seeded random games, per-action
  invariants, deterministic replay, and passive and delivery-first strategy
  tests for 2–4 players under both end-game rules. `feature/game-logic-closeout`
  tests restoration during replay. Exhaustive rule-by-rule
  rejection, boundary, and EC-ID coverage remains.
- **[FR24 - State restoration](PRD.md#fr24-state-restoration)**
  PR #26 added validating `GameState` decoding, cross-owner invariants,
  corruption tests, and deterministic continuation. `feature/game-logic-closeout`
  adds per-good card conservation, draft-state validation and overflow-safe
  stock checks. A broader malformed-state audit remains.
- **[FR21 - Bot placeholders](PRD.md#fr21-bot-placeholders)**
  PR #26 included a generic passive bot. `feature/game-logic-closeout` adds the
  concrete `GamePassiveBot` alias; the approved empty-list result remains `nil`.
- **[FR22 - Error layering](PRD.md#fr22-error-layering)**
  Existing mappings and action rejection were integrated in PR #26.
  `feature/game-logic-closeout` adds missing context conversions and tests;
  localized descriptions and exhaustive rejection tests still need work.

## Planned

No unstarted PRD section 7 requirements are currently tracked here.

## Ready to merge

- **F26 - Game session**
  `feature/game-logic-closeout` provides a `GameSession` facade over the
  existing store, with deterministic creation, state restoration, player views,
  legal actions, serialized submissions, updates and final standings. Tests
  exercise complete games, scoring, purchases, replay and concurrency.
  `snapshot()` is host-only full state; player consumers use `playerView(for:)`.
  The earlier separate `feature/F26-Game-Session` worktree remains untouched.

## Done

- **[FR1 - Game configuration](PRD.md#fr1-game-configuration)**  
  Implemented on `working-on-package` at `3a69ddd`: configuration, validation,
  seed factory and serialization. Seven targeted tests passed on 2026-11-09.
  Configurable rules were integrated in PR #26.
- **[FR2 - Deterministic randomness](PRD.md#fr2-deterministic-randomness)**
  Seeded setup, first-player selection and persisted random state are tested
  and integrated into `working-branch` in PR #26.
- **[FR3 - Coins](PRD.md#fr3-coins)**
  Implemented on `feature/fr3-coins` and merged into `working-on-package`.
  The maximum balance is configured as 5,000 in `Coins`; initialization,
  decoding and additions reject higher balances. This is a user-directed
  change from the PRD; integer overflow remains separately guarded.
  Fourteen targeted tests passed on 2026-11-09.
- **[FR4 - Banking](PRD.md#fr4-banking)**
  Implemented on `feature/fr4-banking` and merged into `working-on-package`.
  Twelve targeted tests passed on 2026-11-09, including atomicity and invalid
  restoration coverage.
- **[FR5 - Goods and cards vocabulary](PRD.md#fr5-goods-and-cards-vocabulary)**
  Implemented on `feature/fr5-goods-and-cards-vocabulary` and integrated into
  `func-req-work`.
- **[FR6 - Draw deck](PRD.md#fr6-draw-deck)**
  Implemented on `feature/FR6-draw-deck` and merged into `working-branch` in
  PR #16.
- **[FR7 - Hand](PRD.md#fr7-hand)**
  Implemented on `feature/FR7-hand` and integrated into `working-branch`.
  Configurable limits and cross-owner restoration were integrated in PR #26.
- **[FR8 - Cube supply](PRD.md#fr8-cube-supply)**
  Merged into `working-branch` in PR #17.
- **[FR9 - Ships](PRD.md#fr9-ships)**
  Merged into `working-branch` in PR #23.
- **[FR10 - Marketplace](PRD.md#fr10-marketplace)**
  Merged into `working-branch` in PR #20.
- **[FR11 - Special cards](PRD.md#fr11-special-cards)**
  Merged into `working-branch` in PR #22; engine effects were integrated in PR #26.
- **[FR12 - Turn flow](PRD.md#fr12-turn-flow)** and
  **[FR13 - Cube snake draft](PRD.md#fr13-cube-snake-draft)**
  Merged into `working-branch` in PR #24.
- **[FR20 - Game store](PRD.md#fr20-game-store)**
  Actor-serialized actions and ordered updates were integrated in PR #26.
- **[FR25 - Game rules](PRD.md#fr25-game-rules)**
  Configurable, validated and serializable rules were integrated in PR #26.

## Verification

The full `MerchantsGame` suite passed on `feature/game-logic-closeout`:
119 XCTest tests and 69 Swift Testing tests, including complete session
lifecycles and intermediate restoration in seeded replay.

FR2 generator, actual game setup, restoration and seeded replay tests passed
on `feature/FR20-FR23-FR24-FR25-bundle`: six XCTest tests and six Swift
Testing tests.

The full `MerchantsGame` regression suite passed on
`feature/FR20-FR23-FR24-FR25-bundle`: 119 XCTest tests and 57 Swift Testing
tests. The package remains free of SwiftUI, UIKit, and AppKit.

The full `MerchantsGame` regression suite passed on
`feature/FR16-FR18-FR19-engine`: 112 XCTest tests and 35 Swift Testing tests.
The engine tests include both end-game rules and equal-turn final rounds for
two, three, and four players.

The full `MerchantsGame` package regression suite passed on
`Feature/FR12-TurnOrder`: 99 tests, including 12 turn-flow and draft tests.

The full `MerchantsGame` package regression suite passed on
`feature/-FR11-special-cards`: 82 tests, including nine Special Cards tests.

The full `MerchantsGame` package regression suite passed on
`feature/FR9-ships-redo`: 78 tests, including five Ships tests.

On 2026-11-09, the full `MerchantsGame` package regression suite passed on
`feature/F8-cube-supply`: 68 tests, including ten Cube Supply, eight Draw Deck,
and six Hand tests.

## Baseline and PRD discrepancy

Checked on 2026-11-09: FR1 and FR2 were reviewed on `working-on-package`.
Its PRD removes warehouse requirements that are still present in the PRD on
the board's original branch. This board follows the integration branch's PRD;
reconcile the discrepancy before implementing or merging affected work.
