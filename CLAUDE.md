# Pourfect — Flutter app

Ball-sort puzzle game. Android first, iOS later. Fully playable offline; the
backend is strictly optional enrichment and must never block gameplay.

The product constraint behind almost every decision here: **zero user-acquisition
budget**. Every install comes from Play organic search, and Play weights 60-day
retention heavily. Targets are D1 > 35% and D7 > 15% against a median of 14%/4%.
When a decision trades revenue against retention, retention wins.

## Commands

```bash
dart test test/engine          # engine suite; ~4 min (the 1,000-board sweep)
dart run tool/check_layering.dart   # layering rules — run before every commit
dart analyze lib test tool
```

Engine tests run under plain `dart test`, not `flutter test` — no device, no
Flutter binding. That is a deliberate consequence of the layering rule below.

## Layering — the rule that matters most

```
engine/   PURE DART. No Flutter, no Riverpod, no dart:ui.
   ↓
state/    Riverpod. Owns the undo stack, selection, persistence, sync.
   ↓
ui/       Widgets. May import engine VALUE TYPES; never engine LOGIC.
```

`ui/` may import `board.dart`, `move.dart`, `level.dart` (or the
`engine_types.dart` barrel). Widgets legitimately need to talk about a `Board`,
a `Tube`, a `Move` and a `Level`; re-wrapping those into parallel UI DTOs would
be pure ceremony.

`ui/` may **not** import `rules.dart`, `solver.dart`, `generator.dart`,
`difficulty.dart` or `canonical.dart`. Game decisions belong in `state/`, where
they are testable without pumping a widget tree.

`tool/check_layering.dart` enforces both directions and exits non-zero. It is
not optional — a single convenient import is all it takes, and by the time
anyone notices, it is a refactor rather than a one-line fix.

## State management

**Riverpod, manual providers only.** No `@riverpod`, no `build_runner`, no
mixing styles. The provider graph is small enough that code generation buys
nothing and costs a build step. A mixed codebase is how the reference project
ended up carrying provider + bloc + riverpod + get_it simultaneously.

Riverpod lives in `state/` and nowhere else. Riverpod appearing in `engine/` is
a regression, and the layering check will fail on it.

## Engine notes

- **Colour ids are opaque ints.** The engine never knows what a colour looks
  like. `ui/theme` is the only place mapping an id to a palette entry and glyph.
- **Moves carry the whole contiguous top run**, clamped by destination free
  space. This is a rule, not an optimisation — moving one ball at a time is the
  difference between satisfying and tedious.
- **`canonicalKey` collapses tube ORDER.** Biggest speedup in the solver by a
  wide margin. Do not optimise it away.
- **The solver returns OPTIMAL paths.** `minMoves` is proven, not estimated,
  because it drives both the star rating and the server-side anti-cheat floor.
  Optimality is pinned by a test comparing against an independent BFS oracle.
- **`SolveUnknown` is never treated as solvable.** Conflating "I gave up" with
  "impossible" is exactly how an unsolvable level ships. The generator discards
  undecided boards.
- **Node caps are set from measurement.** `kGenerationNodeCap` = 1.5M (hardest
  shipping band peaks at ~602k). `kHintNodeCap` = 300k, to be re-tuned against a
  real low-end device in stage 7.
- **Generation is random-fill-plus-verify, never reverse-shuffle.** Reverse
  shuffle drifts back toward trivial and yields no honest `minMoves`. Levels are
  baked at build time by `tool/`; the generator never runs on a device.
- With **1 empty tube, ~99% of random deals are unsolvable**. That statistic is
  the whole argument for verify-don't-trust generation.

## Design direction

Deep calm dark. Near-black ink ground, frosted-glass tubes, muted jewel balls,
hairline borders. References are deliberately **outside the genre**: meditation
apps, premium habit trackers, high-end audio equipment UI, tasteful
glassmorphism. Explicitly avoid the mobile-puzzle house style — no rainbow
gradients, no cartoon bevels, no bouncy display fonts, no confetti.

Palette is defined as **semantic tokens** (`surface`, `surfaceRaised`,
`tubeGlass`, `ballFill`, `hairline`, `textPrimary`, `textMuted`) so a warm-paper
light theme is a token remap rather than a rewrite.

Monospace for all numerics: move counters, timers, level numbers, leaderboard
figures.

**Fonts are bundled TTFs in `assets/fonts/`, declared in pubspec.** Do not add
`google_fonts` — that package exists for runtime fetching, which we explicitly
do not do, and it is dead weight against the 25 MB APK budget.

### Board interaction

Tap-to-select, tap-to-pour.

- Tapping the already-selected tube **deselects** it. Without this a player who
  changes their mind has to waste a move or hit undo.
- Illegal destinations dim to **40%** while a run is held — not 30%, which
  crushes muted jewel tones into near-invisibility on a dark ground.
- Level complete: finished tubes settle, a soft glow rises, **one** chime, then
  the board fades. Deliberate, not empty. This is the moment the game earns its
  "satisfying" pitch.

### Accessibility

Every ball carries **colour AND a distinct shape glyph, always both** — not a
mode that swaps one for the other.

**Maximum 10 simultaneous colours** (`kMaxColours`). This is an accessibility
ceiling, not a search limit: past ten, glyphs stop being tellable apart at ball
size and the muted palette runs out of separable hues. A board you squint at is
not relaxing, which is the product. Get difficulty from fewer empty tubes,
higher scatter and lower forced-move ratio instead. Raising this constant
requires re-running the CVD harness, not just editing the number.

## Analytics (stage 7)

Behind a thin `AnalyticsService` interface, same shape as the ad service, so it
is swappable and testable. Firebase Analytics is the first implementation.

Required events: `level_start`, `level_complete` (level_id, moves, stars,
duration), `level_abandon`, `hint_used`, `undo_used`, `power_up_used`,
`ad_shown`, `ad_completed`, `iap_viewed`, `iap_purchased`.

The point is a **per-level funnel**: finding the levels that kill retention and
re-tuning them. Ship this with the UI, not after.

## Monetization

- Rewarded video is the primary driver — treat it as a feature players want.
- **Undo is always free and unlimited.** It is a retention feature, never a
  monetization one.
- Interstitials only at natural breaks (after level completion), frequency
  capped, hard cooldown. Never mid-level, never on restart.
- One IAP: Remove Ads, $1.99. Kills interstitials, keeps rewarded opt-in.
- Audience skews low-eCPM, so volume and retention beat aggressive placement.
  A 1-star review costs more than an interstitial earns.

## Auth — v1 limitation to be honest about

v1 uses **Firebase anonymous auth only**. No sign-in wall; first-launch friction
is a measurable D1 killer and nothing in v1 needs a real identity.

**An anonymous Firebase UID does not survive uninstall or a device change.** So
v1 "cloud sync" protects against app-data loss only — NOT device migration.
Never surface it in the UI as anything stronger than that: do not say "your
progress is safe" or show a device-transfer affordance. Leave a clean seam for
linking the anonymous UID to a real account later (Firebase supports
`linkWithCredential` on the existing anonymous user, which preserves the UID and
therefore all server-side progress).

## Secrets

`google-services.json`, keystores and `key.properties` are gitignored and must
stay that way. `.claude/` IS tracked on purpose, to share project knowledge
across devices — never put credentials in it.
