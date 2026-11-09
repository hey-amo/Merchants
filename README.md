# Merchants-Swift

## About

This is based of a Reiner Knizia game `Merchants (2007)`.

Note: This version is different to Knizia's game in several ways.

## Overview

Players act as merchants in the age of sail, and deliver cargo to the market to get coins. 

The winner is the player with the most coins

## Bot smoke test

From the repository root, run a disposable two-bot game in the package test runner:

```sh
cd MerchantsGame
SMOKE_ROUNDS=5 swift test --filter SmokeGameTests/runBotGame
```

Set `SMOKE_ROUNDS` to a number from 1 to 10. A round is one player's complete
turn; the initial cube draft does not count. The test stops at that limit or as
soon as the draw deck is empty, even if the configured rules would otherwise
continue a final round. The default pause is two seconds before each action;
set `SMOKE_DELAY_MS=0` to run without the pause (maximum 10000 milliseconds).

The test uses fixed-seed, in-memory game data and does not load or save any
game. Stop it with Ctrl-C without affecting app game data. Output shows each
active player's hand and ships, but not other players' hands. This interactive
test is skipped in ordinary test runs unless `SMOKE_ROUNDS` is set.
