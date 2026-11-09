# Merchants-Swift

## About

This is based of a Reiner Knizia game `Merchants (2007)`.

Note: This version is different to Knizia's game in several ways.

## Overview

Players act as merchants in the age of sail, and deliver cargo to the market to get coins. 

The winner is the player with the most coins

-------

House rules: how this version differs from the original *Merchants*
>
> This is an unofficial digital implementation. It is **not** identical to the printed game. Every change is listed here with its reason, so purists know exactly what differs.
>
> ### Gameplay changes
>
> | Change | Original | This version | Why |
> |---|---|---|---|
> | **Hand limit** | No limit | **6 cards** (8 with a Customs House) | Keeps hands readable on a phone screen and stops games stalling while players hoard cards. |
> | **Drawing needs room** | Draw 2 always possible | Draw 2 is only available if your hand can hold both cards. If you can't draw, you **must deliver**. | Makes the hand limit forcing: a full hand moves the game forward. |
> | **Office** | Draw a card after your second action every turn | Draw **+1 card per Office, only when you take Draw 2**, automatically. Limited by hand room and the deck; you draw what is possible. | Ties Office to the drawing action, so it rewards drawing instead of silently speeding up the deck. |
> | **Docker → Crane** | One extra exchange per Docker in Phase I, whatever your action | **Only when you take the Exchange action:** +1 exchange per Crane. Buying a Crane gives one free optional exchange. Pass and other purchases give nothing. | Tighter and easier to reason about: the card improves exchanging and nothing else. |
> | **Exchange limits** | Not specified | A ship can be exchanged **once per turn**, and a ship you just bought can't be exchanged that turn. | Prevents swap-back-and-forth tricks. A newly bought ship is loaded by you anyway. |
> | **Trade Agreement** | +2 coins per card when you earn coins | +2 per Trade Agreement **only if you earn more than 2 coins** from that scoring (any player's delivery), once per scoring, never per cube. | Stops tiny payouts from triggering a bonus, so the card can't snowball. |
> | **End of game** | Ends immediately when the last card is drawn | **Your choice:** *Immediate* (original) or *One more turn* (play continues until the last seat has played, so everyone has the same number of turns). | Immediate end can favour the players who happen to be earlier in turn order. |
> | **Starting coins** | Not specified | Everyone starts with **0**. | Money comes only from delivering. |
>
> ### New special cards
>
> | Card | Cost | Limit | Effect |
> |---|---|---|---|
> | **Customs House** | 8 | 1 per player | +2 hand limit. |
> | **Large Ship** | 18 | 1 per player | Carries **2** cubes of any colours, loaded when you buy it. |
>
> ### Initial setup has also changed into a snake draft
>
> Setup, the cube snake draft, the six goods, delivery and scoring (all players are paid `cubes × visible matching cards`), and "most coins wins; ties share" are exactly as in the original. Special cards are worth nothing at the end.

-------

## Bot smoke test

A smoke test is implemented, but I don't think it works, and may be disabled in future runs

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
active player's hand and ships, every player's coin balance, and a micro report
after each action with coin changes and updated balances; it does not show
other players' hands. This interactive test is skipped in ordinary test runs
unless `SMOKE_ROUNDS` is set.

-----