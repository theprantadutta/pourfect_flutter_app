# Pourfect — Flutter app

Ball-sort puzzle game. Android first, iOS later. Fully playable offline; the
backend is strictly optional enrichment and must never block gameplay.

The product constraint behind almost every decision here: **zero user-acquisition
budget**. Every install comes from Play organic search, and Play weights 60-day
retention heavily. Targets are D1 > 35% and D7 > 15% against a median of 14%/4%.
When a decision trades revenue against retention, retention wins.

## Commands

```bash
dart test test/engine                 # engine suite, pure Dart; ~8 min
flutter test test/state               # state layer (Riverpod needs Flutter)
dart run tool/cvd_harness.dart        # colour-blindness gate for the palette
dart run tool/check_layering.dart     # layering rules — before every commit
dart run tool/validate_levels.dart    # content gate — before every release
dart analyze lib test tool

dart run tool/generate_levels.dart    # re-bake levels (~4 min); see below
dart run tool/probe_hint_budget.dart  # re-measure kHintNodeCap
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

`ui/` may import `board.dart`, `move.dart`, `level.dart`, `level_set.dart` (or
the `engine_types.dart` barrel). Widgets legitimately need to talk about a
`Board`, a `Tube`, a `Move` and a `Level`; re-wrapping those into parallel UI
DTOs would be pure ceremony. A serialization codec decides nothing about the
game, so `level_set.dart` belongs on this side too.

`ui/` may **not** import `rules.dart`, `solver.dart`, `generator.dart`,
`difficulty.dart`, `canonical.dart` or `level_curve.dart`. Game decisions belong
in `state/`, where they are testable without pumping a widget tree.

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
  shipping band peaks at ~602k). `kHintNodeCap` = 300k, measured by
  `tool/probe_hint_budget.dart` over all 621 positions on the optimal paths of
  the 20 hardest levels: p50 64 nodes, p99 62k, max 192k. Hints get much cheaper
  as a player progresses (start p99 192k → end p99 40), so the expensive request
  is someone opening level 141 and immediately asking.
- **Generation is random-fill-plus-verify, never reverse-shuffle.** Reverse
  shuffle drifts back toward trivial and yields no honest `minMoves`. Levels are
  baked at build time by `tool/`; the generator never runs on a device.
- With **1 empty tube, ~99% of random deals are unsolvable**. That statistic is
  the whole argument for verify-don't-trust generation.
- **The difficulty score is CALIBRATED to 0-100** from a measured raw range of
  ~45-90. Without that, the raw blend is an interval scale and ratio arithmetic
  on it ("25% easier") silently means something far more extreme than intended.
- **`forcedMoveRatio` barely varies on 2-empty boards** (p50 ~0.1 everywhere).
  It is a rare-event indicator and does little discriminating there despite
  carrying the largest weight; it comes alive on the 1-empty band (~0.4).
  `meanBranching` is the continuous view of the same idea and is reported in the
  curve report. Within a band, what actually separates two boards is move load
  and scatter.

## Level content

Two artifacts, both committed, both baked by `tool/generate_levels.dart`:

| Artifact | What | Consumer |
|---|---|---|
| `assets/levels/levels.bin` | 150-level campaign, ~7.8 KB | bundled in the APK |
| `generated/daily_pool.json` | 365 dailies, carries `min_moves` | **the backend** — copy into the API repo's seed data |
| `generated/level_curve.{md,csv}` | the whole curve, for eyeballing | humans |

**Determinism is a hard requirement.** `tool/generate_levels.dart` with default
flags must reproduce `levels.bin` byte-for-byte, and
`test/engine/level_asset_test.dart` fails if it does not. Player progress is
keyed on level id and `minMoves` feeds the server's leaderboard anti-cheat
floor, so a silent reshuffle would repoint every saved star at a board the
player never saw and start rejecting legitimate submissions.

`kLevelSetVersion` bumps on any deliberate curve change **once the game has
shipped**. Pre-launch it stays at 1: the field protects live player progress,
and bumping it on every pre-release re-bake would turn a safety signal into
noise. The moment v1 is on Play, that discretion ends.

`levelSetVersion` is stored in the asset and must be stored on every
`LevelProgress` row, locally and server-side. v1 ships no migration logic and
needs none — the field exists because it cannot be retrofitted.

**The onboarding zone is the part to protect.** Levels 1-8 sit near-flat in
18-30 (a player is learning that a tap pours and that undo is free, not being
tested); 9-15 ease to ~50 and hand off to band two at that level. A hard rail
asserts no step between consecutive non-breather levels up to 20 exceeds 6
points — the first bake had the tutorial climbing at 2.8 points/level against
0.17-0.4 for the whole rest of the game, i.e. the harshest gradient in the
campaign sat exactly where D1 is won or lost.

Pinned tiers (band one) are generated SLOT BY SLOT against narrow sub-windows,
not sampled as a pool. A pool only contains what a shape commonly produces, so
asking 13 four-colour boards to cover 30-52 returns 41-52 — 41 is that shape's
p10. That is how a 13.6-point cliff appeared between levels 8 and 9.

The campaign curve: four bands, colours rising 3→10, with the final band
stepping up by REMOVING an empty tube rather than adding colours. Breathers land
on every tenth level except in the tutorial band and except on a band's last
level (a band should hand off at its peak). A breather must score 25-40% below
the running average of the five levels before it — both bounds matter, since a
ceiling alone produced a level scoring 19 where 57 was allowed.

The daily pool is a **separate artifact with its own seed**, drawn from
mid-campaign shapes and explicitly disjoint from the campaign by canonical key,
so nobody is served a daily they already solved.

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

## Analytics

Behind a thin `AnalyticsService` interface, same shape as the ad service, so it
is swappable and testable. Firebase Analytics is the first implementation.

**`level_abandon` fires on BACKGROUNDING**, not just on a clean exit. Most
players who give up close the app or take a call rather than pressing back, so
a funnel counting only clean exits undercounts abandonment on exactly the hard
levels it exists to find. `GameScreen` observes `AppLifecycleState` and flushes
while the process is still alive. Verified on device:

    level_start   {level_id: 1, min_moves: 5, is_retry: 0}
    level_abandon {level_id: 1, moves: 1, duration_seconds: 13,
                   reason: backgrounded, progress: 0.2}

Opening a level and backgrounding with zero moves is NOT an abandonment — that
is a session event, and counting it would smear noise across every funnel.

The debug mirror uses `debugPrint`, not `dart:developer.log`: the latter posts
to the VM service and never reaches `adb logcat`, so a funnel "verified"
through it is only verified against DevTools being attached.

Required events: `level_start`, `level_complete` (level_id, moves, stars,
duration), `level_abandon`, `hint_used`, `undo_used`, `power_up_used`,
`ad_shown`, `ad_completed`, `iap_viewed`, `iap_purchased`.

The point is a **per-level funnel**: finding the levels that kill retention and
re-tuning them. Ship this with the UI, not after.

## Monetization

- Rewarded video is the primary driver — treat it as a feature players want.
- **Confirm the reward RESOLVED before consuming the ad grant.** A hint can come
  back `SolveUnknown`; charging a player who just watched a video and then
  showing "no hint available" is a refund request and a one-star review. Check
  first, then grant — never the other way round.
- **Undo is always free and unlimited.** It is a retention feature, never a
  monetization one.
- Interstitials only at natural breaks (after level completion), frequency
  capped, hard cooldown. Never mid-level, never on restart.
- One IAP: Remove Ads, $1.99. Kills interstitials, keeps rewarded opt-in.
- Audience skews low-eCPM, so volume and retention beat aggressive placement.
  A 1-star review costs more than an interstitial earns.

## Hints

Solved on a background isolate via `Isolate.run`. Three rules, all enforced in
`state/hint_controller.dart`:

1. **The board stays interactive.** No modal spinner, no disabled tubes — the
   progress ring lives in the Hint button alone. The player asked for help, not
   to be locked out of their own game for a second.
2. **`HintOutcome.resolved` is the only outcome that may consume a reward.**
3. **A hint for a position the player has left is discarded** (`stale`), and
   tapping Hint again while one is solving cancels it.

## The win moment

NOT a dialog. The board transforms: solved tubes glow and stay visible as the
trophy, empty tubes recede to 25%, and the stars, move count, band track and CTA
arrive around the board rather than over it. A card would turn the emotional
payoff of the whole loop into an alert box.

**Duration is earned, not constant.** `WinProfile.full` (1820ms) runs for three
stars, a personal best, or a band's last level. `WinProfile.brief` (1150ms) runs
for everything else — same beats, 120ms star spacing, no present-lift. A player
clearing level 60 on a two-star retry has seen this sixty times.

**Skip must never advance the level.** The skip layer is a separate full-screen
absorber that removes itself after one tap, so Next always needs its own. If a
skip also triggered Next the gesture would become muscle memory and players
would blow through two levels by accident, then correctly blame the game. The
rule is expressed as LAYOUT, not as a flag somebody has to remember to check.

Three stars must feel meaningfully better than two: only the third star fires a
wider ring pulse, a richer tone with an octave on top, a stronger haptic, and a
warm wash across the board glow. Two stars gets none of it, by construction.

## Sound

Every cue is SYNTHESISED at startup (`services/audio/synth.dart`, pure Dart and
unit-tested). Zero audio assets.

**The pour is where the tuning budget goes.** Players hear it thousands of times
a session against the win chime's once per level. Soft 7ms attack, short warm
body, and a pitch that RISES with how full the destination tube is — a filling
vessel shortens its air column, so a run of four plays as a rising figure rather
than the same note four times. Random jitter on top stops two identical pours
sounding stamped. A sampled pour would have exactly one timbre and the ear locks
onto it within a session.

### Audio session — the part that costs reviews

A large share of puzzle players are listening to music or a podcast. If this
game grabs audio focus, their playback stops, and "this game killed my Spotify"
is a one-star nothing else buys back.

- **VERIFIED on Android:** `adb shell dumpsys audio` shows this package in no
  focus entry at all. No focus request is made, so nothing is interrupted.
- **Known gap:** the AAudio stream reports `usage=USAGE_MEDIA`, not
  `USAGE_GAME` — SoLoud opens its own stream natively and bypasses
  `audio_session`'s attributes. Harmless for mixing.
- **UNVERIFIED:** the iOS silent switch. The `ambient` category is requested,
  but since SoLoud demonstrably bypasses the Android attributes it may set its
  own AVAudioSession category too. **Before any iOS build ships, flip the
  hardware mute switch and confirm silence.**

## Level select

Every level is a TUBE holding pips for its stars — the game's own object, not a
numbered square. Bands are sections with name, board shape and progress track,
so the stage-6 curve becomes something a player can see. Headers are sticky and
the list opens scrolled to where the player actually is; 150 tiles is too many
to ask someone on level 96 to hunt through.

**Breathers are not marked.** Labelling one would be condescending and a
confession that the curve is engineered. They work because they are felt.

**No star gate.** Clearing a level opens the next one, full stop.

## Interaction and motion rules

- **Everything tappable goes through `Pressable`** (scale, haptic, sound), so no
  control can be added later that quietly forgets its feedback.
- **Never `MaterialPageRoute`.** Its slide is an OS convention for moving
  between documents. Opening a level grows the board out of the tile the player
  touched (`PourfectPageRoute.fromRect`).
- **Numbers animate.** Counts run up with a decelerating curve so they settle
  rather than appear. Static digits are what make a screen feel like a form.

## Progress

Persisted locally, works with zero network. The merge is monotonic on BOTH stars
and best-moves and order-independent, so a worse replay can never take a star
away — that is the bug that produces "the game deleted my progress".

Every row records `levelSetVersion`. This is what that field was added for.

## APK budget

Measure PER-ABI, the way Play delivers it — never the universal APK.

| Build | Size |
|---|---|
| arm64-v8a | 20.3 MB |
| armeabi-v7a | 16.8 MB |
| universal (never shipped) | 26.9 MB |

Audio costs ~5.4 MB: SoLoud ships native libs for all three ABIs regardless of
`--target-platform`, which filters only Flutter's own libs. The App Bundle
splits them per device.

## Known gaps

- **Fonts are not bundled.** Type resolves to the platform faces (Roboto /
  Roboto Mono). Bundling a chosen pair is a licence decision; `typography.dart`
  is the single swap point.
- **No sound yet.** The completion moment currently lands on haptics alone; the
  single chime described in the design direction still needs an asset.
- **Frame timing.** `adb shell dumpsys gfxinfo` reports ZERO frames for this app
  — Impeller renders to its own surface and bypasses Android's HWUI pipeline, so
  that tool is blind to it. The real measurement is
  `integration_test/pour_perf_test.dart` driven by `test_driver/perf_driver.dart`:

      flutter drive --driver=test_driver/perf_driver.dart         --target=integration_test/pour_perf_test.dart --profile

  Watch BOTH halves: build time is Dart work (too much per-frame recomputation),
  raster time is GPU work (shaders, blurs, overdraw — which is why
  `BackdropFilter` is banned here).
- **No settings, daily challenge, leaderboard or store screens yet.**

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
