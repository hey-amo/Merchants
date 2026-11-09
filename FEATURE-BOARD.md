# Feature requirements board

This board tracks [PRD section 7](PRD.md#7-feature-requirements). Treat
`PRD.md` as read-only; update this board as work progresses. Each card links
to the full requirement, including its acceptance criteria and tests.

## How to use

- **Integration branch:** `working-on-package`. Create feature branches from
  it and target it with pull requests; do not merge this work into `main`.
- **Planned:** not started or not yet assessed.
- **In progress:** started, but not complete against the PRD.
- **Ready to merge:** implemented and tested on a separate branch, but not yet
  present on `working-on-package`.
- **Done:** present on `working-on-package` and verified against the requirement.

Move cards between sections as their status changes. Record the branch and
remaining work for partially completed cards; do not mark a feature done solely
because a component or placeholder exists.

## Ready to merge

No features ready to merge yet.

## In progress

- **[FR2 - Deterministic randomness](PRD.md#fr2-deterministic-randomness)**  
  `working-on-package` at `3a69ddd` has a seeded generator, Fisher-Yates
  shuffle and first-player selection; six targeted tests passed on 2026-11-09.
  Remaining: integrate random state into `GameState`, use it for the actual
  deck and first-player setup, and verify the end-to-end randomness and replay
  requirements. The implementation is on the integration branch; the remaining
  integration work is not.

## Planned

- [FR3 - Coins](PRD.md#fr3-coins)
- [FR4 - Banking](PRD.md#fr4-banking)
- [FR5 - Goods and cards vocabulary](PRD.md#fr5-goods-and-cards-vocabulary)
- [FR6 - Draw deck](PRD.md#fr6-draw-deck)
- [FR7 - Hand and warehouse](PRD.md#fr7-hand-and-warehouse)
- [FR8 - Cube supply](PRD.md#fr8-cube-supply)
- [FR9 - Ships](PRD.md#fr9-ships)
- [FR10 - Marketplace](PRD.md#fr10-marketplace)
- [FR11 - Special cards](PRD.md#fr11-special-cards)
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

## Baseline and PRD discrepancy

Checked on 2026-11-09: this board's branch has a placeholder game package;
FR1 and FR2 were reviewed on `working-on-package`. The integration branch has
its own version of the PRD, which removes warehouse requirements that are still
present in this branch's PRD. This board follows the PRD in this branch;
reconcile the discrepancy before implementing or merging affected work.
