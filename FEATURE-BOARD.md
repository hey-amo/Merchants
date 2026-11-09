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

## Ready to merge

- **[FR9 - Ships](PRD.md#fr9-ships)**
  Implemented and tested on `feature/FR9-ships-redo`. PR #21 merged it into
  `working-on-package`, not `working-branch`; it still needs integration into
  `working-branch`.
- **[FR11 - Special cards](PRD.md#fr11-special-cards)**
  Implemented and tested on `feature/-FR11-special-cards`; awaiting integration
  into `working-branch`. The turn engine will apply the effects during play.

## In progress

- **[FR2 - Deterministic randomness](PRD.md#fr2-deterministic-randomness)**  
  `working-on-package` at `3a69ddd` has a seeded generator, Fisher-Yates
  shuffle and first-player selection; six targeted tests passed on 2026-11-09.
  Remaining: integrate random state into `GameState`, use it for the actual
  deck and first-player setup, and verify the end-to-end randomness and replay
  requirements. The implementation is on the integration branch; the remaining
  integration work is not.

## Planned

- [FR12 - Turn flow](PRD.md#fr12-turn-flow)
- [FR13 - Cube snake draft](PRD.md#fr13-cube-snake-draft)
- [FR14 - Planning phase](PRD.md#fr14-planning-phase)
- [FR15 - Trading phase](PRD.md#fr15-trading-phase)
- [FR16 - Delivery scoring](PRD.md#fr16-delivery-scoring)
- [FR17 - End game and winners](PRD.md#fr17-end-game-and-winners)
- [FR18 - Game actions and events](PRD.md#fr18-game-actions-and-events)
- [FR19 - Game engine and player view](PRD.md#fr19-game-engine-and-player-view)
- [FR20 - Game store](PRD.md#fr20-game-store)
- [FR21 - Bot placeholders](PRD.md#fr21-bot-placeholders)
- [FR22 - Error layering](PRD.md#fr22-error-layering)
- [FR23 - Testing and replay](PRD.md#fr23-testing-and-replay)
- [FR24 - State restoration](PRD.md#fr24-state-restoration)
- [FR25 - Game rules](PRD.md#fr25-game-rules)

## Done

- **[FR1 - Game configuration](PRD.md#fr1-game-configuration)**  
  Implemented on `working-on-package` at `3a69ddd`: configuration, validation,
  seed factory and serialization. Seven targeted tests passed on 2026-11-09.
  The rules value is a placeholder pending FR25.
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
  The base hand limit remains a standard-rules placeholder pending FR25;
  cross-owner restoration and player-view validation remain part of FR24 and
  FR19 respectively.
- **[FR8 - Cube supply](PRD.md#fr8-cube-supply)**
  Merged into `working-branch` in PR #17.
- **[FR10 - Marketplace](PRD.md#fr10-marketplace)**
  Merged into `working-branch` in PR #20.

## Verification

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
