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

- **[FR23 - Testing and replay](PRD.md#fr23-testing-and-replay)**
  PR #26 added seeded random games, per-action
  invariants, deterministic replay, and passive and delivery-first strategy
  tests for 2–4 players under both end-game rules. `feature/coregp-acceptance`
  exercises 60 seeded random games, comparing every replayed state and event,
  checks per-player coin changes, and restores and continues at every phase
  for all player counts and ending rules. Additional EC-labelled boundary
  tests cover draw, delivery, planning and endings. Exhaustive rule-by-rule
  rejection, boundary, and EC-ID coverage remains.
- **[FR24 - State restoration](PRD.md#fr24-state-restoration)**
  PR #26 added validating `GameState` decoding, cross-owner invariants,
  corruption tests, and deterministic continuation. `feature/coregp-acceptance`
  adds per-good card conservation, draft-state validation, overflow-safe
  stock checks and Crane ownership validation for active planning progress.
  Required top-level fields are tested for missing, null and wrong-type data.
  A broader malformed-state audit remains.
- **[FR21 - Bot placeholders](PRD.md#fr21-bot-placeholders)**
  PR #26 included a generic passive bot. `feature/coregp-acceptance` adds the
  concrete `GamePassiveBot` alias; the approved empty-list result remains `nil`.

## Planned

No unstarted PRD section 7 requirements are currently tracked here.

## Ready to merge

- **[FR19 - Game engine and player view](PRD.md#fr19-game-engine-and-player-view)**
  The engine, data-only player projection, legal actions and deterministic
  setup were integrated into `working-branch` in PR #26.
  `feature/coregp-acceptance` adds event, projection, legal-action and rejection
  checks, plus complete game and replay coverage. No known FR19 implementation
  defect is currently recorded. Exhaustive rejection coverage is deferred;
  the broader malformed-state audit remains separate FR24 work.
- **[FR22 - Error layering](PRD.md#fr22-error-layering)**
  Existing mappings and action rejection were integrated in PR #26.
  `feature/coregp-acceptance` adds context conversions, tests, UK-English
  descriptions and a generic `Game error --` message for engine errors and
  action rejections. For local gameplay the user accepts existing coverage
  instead of requiring an exhaustive rejection audit.
- **[FR18 - Game actions and events](PRD.md#fr18-game-actions-and-events)**
  `feature/coregp-acceptance` verifies exact events for all eight actions,
  Office and ending events, Codable round trips, count-only draw events, and
  action rejection context and atomicity. Rejected actions do not publish
  updates. Delivery placements expose `.hand(good)` while retaining the existing
  `card` initializer and Codable representation for compatibility.
- **[FR14 - Planning phase](PRD.md#fr14-planning-phase)**,
  **[FR15 - Trading phase](PRD.md#fr15-trading-phase)**,
  **[FR16 - Delivery scoring](PRD.md#fr16-delivery-scoring)** and
  **[FR17 - End game and winners](PRD.md#fr17-end-game-and-winners)**
  Implemented on `working-branch` in PR #26 and verified together on
  `feature/coregp-acceptance`, including purchase boundaries, planning and
  trading effects, delivery scoring, and both end rules. Large Ships can now
  be purchased with one or two cubes as explicitly confirmed by the user;
  legal actions and state restoration support both loads.
- **F26 - Game session**
  `feature/coregp-acceptance` provides a `GameSession` facade over the
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
  Actor-serialized actions and ordered `AsyncStream` updates are implemented,
  tested and integrated into `working-branch` in PR #26.
- **[FR25 - Game rules](PRD.md#fr25-game-rules)**
  Configurable, validated and serializable rules are tested and integrated
  into `working-branch` in PR #26.

## Verification

`feature/coregp-acceptance` adds UK-English placeholder descriptions using
`String(localized:bundle:)`. The existing SwiftPM build reports an unhandled
string-catalog resource; the source-language text is used as a fallback and
translations require the resource-processing issue to be addressed.

The full `MerchantsGame` suite passed after the FR23 replay and restoration
coverage changes: 122 XCTest tests and 97 Swift Testing tests, including
engine-level coverage, complete session lifecycles and seeded replay.

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

## Remaining acceptance plan

1. **Rejections (FR23, deferred):** inventory every error case and each engine
   action against the PRD and existing tests. Create a matrix of happy path,
   each reachable rejection and boundaries, including wrong player/phase,
   funds, stock, supply, ship and hand limits, and finished games. For each
   engine rejection, assert the exact mapped error, player and action, unchanged
   state and no store update; assert it is absent from legal actions when
   applicable. Test unreachable internal errors directly at their owner and
   record why they cannot arise through valid play. Use EC IDs in test names.
   FR18 now covers each action family and representative boundary failures;
   this broader owner-error audit is deferred for local gameplay; EC-labelled
   tests now also cover additional planning, trading, scoring and ending
   boundaries.
2. **Malformed state (FR24/FR23):** inventory all owner decoders and
   cross-owner invariants, then mutate valid encoded fixtures one field at a
   time. Cover missing, null, wrong-type, negative, oversized and inconsistent
   counts; player identities, draft/turn/ending combinations, fleets, stock,
   hands, deck and marketplace. Assert the exact owner or `GameStateError`
   and that no invalid state is returned or arithmetic traps. Round-trip valid
   setup, draft, planning, trading, final-round and finished states; replay
   identical legal actions after restoration across seeds, player counts and
   ending rules. Continuation at every phase is covered for all player counts
   and both ending rules with one seed, and periodic restoration is checked
   across the seeded random games. The remaining decoder inventory and
   corruption matrix are still open.
3. Base the audits on the integrated closeout changes, which already add error
   mappings, malformed-state checks and intermediate replay tests, to avoid
   duplicating or overwriting them.

## Baseline and PRD discrepancy

The user confirmed that a Large Ship may be purchased with one or two cubes,
resolving the conflict between EC-30 and the two-cube purchase wording in the
locked PRD. FR15's test list also says drawing two cards at hand size 7 and
limit 8 is legal; the explicit EC-25 rule requires room for both cards unless
only one remains in the deck, and the tests follow EC-25.

Checked on 2026-11-09: FR1 and FR2 were reviewed on `working-on-package`.
Its PRD removes warehouse requirements that are still present in the PRD on
the board's original branch. This board follows the integration branch's PRD;
reconcile the discrepancy before implementing or merging affected work.
