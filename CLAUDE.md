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
dart run tool/cvd_harness.dart        # color-blindness gate for the palette
dart run tool/check_layering.dart     # layering rules — before every commit
dart run tool/validate_levels.dart    # content gate — before every release
dart analyze lib test tool

dart run tool/generate_levels.dart    # re-bake levels (~4 min); see below
dart run tool/probe_hint_budget.dart  # re-measure kHintNodeCap
```

Engine tests run under plain `dart test`, not `flutter test` — no device, no
Flutter binding. That is a deliberate consequence of the layering rule below.

## US English, everywhere

**"color", never "colour"** — in the store listing, in every user-facing string,
and in every identifier and comment in the codebase. This is not a style
preference: "color sort" carries materially more search volume than the British
spelling, and organic search is our only acquisition channel.

The codebase was swept once (319 occurrences) and it must stay swept. Before
committing:

    grep -ri "colour" --include="*.dart" --include="*.md" lib test tool

It also happens to match Flutter's own `Color`, so the engine no longer mixes
`ColorId` with `maxColour` the way it did.

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

- **Color ids are opaque ints.** The engine never knows what a color looks
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
asking 13 four-color boards to cover 30-52 returns 41-52 — 41 is that shape's
p10. That is how a 13.6-point cliff appeared between levels 8 and 9.

The campaign curve: four bands, colors rising 3→10, with the final band
stepping up by REMOVING an empty tube rather than adding colors. Breathers land
on every tenth level except in the tutorial band and except on a band's last
level (a band should hand off at its peak). A breather must score 25-40% below
the running average of the five levels before it — both bounds matter, since a
ceiling alone produced a level scoring 19 where 57 was allowed.

**Daily challenges are NOT generated here.** The backend generates them at
runtime, seeded from the date plus a salt that exists only in that private
repo. They used to be baked into `generated/daily_pool.json` by the tool
below — but this repo is public and generation is deterministic, so shipping
the pool AND its seed published every board for the next year together with
its proven optimal solution. Removing just the file would not have helped;
the seed alone regenerates it.

That matters because the anti-cheat floor rejects submissions BELOW `minMoves`
and cannot tell an honest optimum from a looked-up one. See the backend's
`DailyChallengeJobService`.

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

Every ball carries **color AND a distinct shape glyph, always both** — not a
mode that swaps one for the other.

**Maximum 10 simultaneous colors** (`kMaxColors`). This is an accessibility
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

## Frame timing

`adb shell dumpsys gfxinfo` reports ZERO frames for this app — Impeller renders
to its own surface and never touches Android's HWUI pipeline, so that tool is
blind to it. `integration_test` + `flutter drive` is the documented alternative
and the harness is in the repo, but it needs the on-device test to reach the
host VM service and fails here with a connection refused.

What actually works: `FrameWatch` (`services/perf/frame_watch.dart`) uses
Flutter's own `addTimingsCallback`, so the app measures itself and prints to
logcat. Profile/debug only.

    flutter build apk --profile --target-platform android-arm64
    adb logcat | grep '\[frames\]'

**Measured on a Samsung A24 (mid-range), driving real pours and undos:**

| Window | Build p50 / p95 / max | Raster p50 / p95 / max | Janky |
|---|---|---|---|
| startup | 1.14 / 2.00 / 18.29 ms | 4.85 / 12.33 / 223.73 ms | 3/241 (1.2%) |
| steady | 1.13 / 2.07 / 4.56 ms | 4.49 / 6.96 / 11.03 ms | **0/246** |
| steady | 1.17 / 1.98 / 4.42 ms | 4.56 / 7.36 / 12.99 ms | **0/243** |

Budget is 16.67ms at 60Hz. Steady-state play uses about **1.2ms build + 4.5ms
raster**, so roughly a third of the frame. The 223ms raster spike in the first
window is first-frame shader compilation at startup, not gameplay.

Report BOTH halves when investigating: build is Dart work (too much per-frame
recomputation), raster is GPU work (shaders, saveLayers, overdraw — which is why
`BackdropFilter` is banned here).

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

- **Manrope is not bundled yet.** JetBrains Mono is in and rendering (the
  slashed zero is the tell on device); the UI face still falls back to the
  platform default. `kUiFontFamily` in `typography.dart` is the single swap
  point, and `assets/licenses/` still needs the two OFL texts.
- **No daily challenge or leaderboard screens.** Both wait on the client work;
  the backend serves them already.
- **No Sign in with Apple.** Android-only for now, so it costs nothing yet — but
  it blocks the first iOS submission, because Apple requires it alongside any
  other social login.
- **The existing-Google-account path has never run against real Firebase.** The
  logic and its tests are in (`signInToExistingGoogleAccount`), but a returning
  player on a new phone with an already-registered Google account has not been
  exercised on hardware.
- **No IAP product exists yet.** The Play and App Store product ids and the
  Play license key are still blank in `generated/ad_config.md`, so Remove Ads
  shows an em dash instead of a price. That is the correct degraded state, not
  a bug — but it means the purchase flow itself is still unexercised.
- **`kPrivacyPolicyUrl` is a placeholder domain**, invented rather than
  confirmed. The policy page exists at `generated/privacy_policy.html`; the URL
  it will live at does not. Play rejects a dead privacy link.
- **The interstitial has never been seen on a device.** Its rules have 16 tests
  and its display plumbing is shared with rewarded video, which IS verified on
  hardware — but nobody has yet played to level 10 in a release build and
  watched one appear. Do that before the first public track.
- **The Android activity is still `com.example.pourfect_flutter_app`.** The
  applicationId is correct (`com.pranta.pourfect`) and Play only reads that, so
  this is cosmetic — it shows up in `adb` and in stack traces.

## Ads — live ids, gated on build mode

`ad_ids.dart` holds both sets, and **`kReleaseMode` decides**, not a constant
somebody flips:

    release           → our live units
    debug / profile   → Google's test units, always

The direction is the point. A flat "swap when you go live" leaves every
developer build serving real ads, and tapping your own live ad is the most
reliable way to get an AdMob account flagged for invalid traffic — weeks to
appeal, revenue line down throughout. Every developer build is a build
somebody taps ads in, so relying on discipline is relying on nothing.
`test/services/ad_ids_test.dart` runs in debug, which is exactly the mode that
must never serve live ads, so it can prove the rule holds.

**`kAdMobTestDeviceIds` closes the one remaining door.** A release build on a
developer handset would otherwise take live impressions. The dev Samsung A24
is registered; read a new id from a PROFILE build so obtaining it costs no
impression:

    adb logcat | grep "setTestDeviceIds"

The manifest carries the LIVE app id in every build. Test ad UNITS serve under
any app id, so a second value there would only be one more thing to keep in
step. Note the format trap: app ids use `~`, unit ids use `/` — and a unit id
in the manifest crashes on launch while an app id in Dart silently never loads
an ad, which is much harder to trace.

The four rewarded units are distinct per placement, so AdMob reports fill and
revenue per placement. Sharing one would make "rewarded earns well" a single
number that cannot say whether the hint, the extra tube or the skip is doing
the work.

**No banner ads.** Decided 2026-08-28. A permanent banner is the most
house-style element available and undercuts the premium positioning that is
the whole differentiator; it also steals height from `BoardGeometry`, which
already solves ball size against available space and overflowed once at level
150. Banner eCPM is roughly two orders of magnitude below rewarded, so it
would trade the product's identity for rounding-error revenue. Rewarded video
stays the primary driver.

## Lazy providers spend before they remember

`monetizationProvider` is lazy — nothing builds it until the first hint is
asked for — so `build()` and the first spend happen in the same breath. The
free-hint budget was therefore always measured against a freshly-zeroed
counter, and **every launch handed out a fresh set of free hints**. The
rewarded prompt, which is the primary revenue driver, was unreachable for
anyone willing to reopen the app.

Two rules came out of it, both pinned by tests:

- **Await the restore before spending anything persisted.**
  `consumeFreeHint` waits on the future `build()` kicked off.
- **Restores must be monotonic.** Assigning the stored value unconditionally
  walks the counter backwards when a spend lands mid-load, handing the spent
  hint straight back.

The funnel would NOT have caught this: `hint_used` fires either way, so the
analytics looked healthy while the paywall never appeared. Any provider that
persists a spendable balance has the same shape — check it the same way.

## Ad placements without a feature behind them

`PowerUpUsed` is defined in the analytics events and has **zero call sites**.
`RewardedPlacement.extraTube` and `RewardedPlacement.levelSkip` exist, have
live AdMob units, and are preloaded on every launch — but nothing can ever
show them, because neither power-up is implemented as gameplay.

So two of the four ad units burn a load request per session and can never
record an impression. Either build the features or stop preloading those
placements; leaving it as-is makes AdMob's fill-rate reporting meaningless for
half the inventory.

## Monetization — verified on device

An arm64 release build on a Samsung A24, 2026-08-28:

- Three free hints, then the "Watch a video for a hint?" prompt, then a real
  rewarded video carrying the **Test Ad** label, then the hint actually
  arrives. The whole rewarded chain, end to end.
- `com.google.android.gms.ads.AdActivity` confirmed in the foreground via
  `dumpsys window`, so the ad is genuinely showing rather than being reported
  as shown.
- Settings renders in full: Feel, Visibility, Support, Progress, About. The
  Remove Ads price shows an em dash because the product is not Active in Play
  Console yet, which is the correct degraded state and not an error.

**A provider that throws is INVISIBLE in a release build.** It renders as a
blank grey rectangle, not a red error box, and the exception names only the
provider — nothing points at the screen that vanished. `MonetizationController`
assigned `state` inside `build()`, which Riverpod forbids, and the whole
settings screen simply was not there. The cheap defence is a test that merely
CONSTRUCTS every Notifier a screen can reach; it catches this class of bug in
milliseconds instead of a build-install-screenshot round trip.

## Auth — anonymous by default, sign-in as an upgrade

Players still start **anonymous, with no sign-in wall**, and that is not
negotiable: first-launch friction is a measurable D1 killer and nothing about a
ball-sort puzzle needs a real identity. Signing in is offered from Settings and
from nowhere else.

Google and email/password both land. `services/api/identity.dart` owns the
Firebase side behind an `Identity` seam, so the whole flow is testable without a
project, an emulator or a network; `state/account_controller.dart` owns
everything that has to happen around it.

**Signing in is an UPGRADE, never a migration.** `linkWithCredential` keeps the
same uid, so the server row and every star hanging off it survive untouched.
This is why anonymous-first costs nothing later. Three rules fall out of it, all
pinned by tests:

- **Link when anonymous, sign in when not.** Signing in from an anonymous
  session switches to a different uid and silently abandons the progress.
- **Force a session re-exchange afterwards.** The backend learns somebody signed
  in ONLY from `sign_in_provider` in the next token it verifies. The cached
  session has not expired — it is simply describing a player who no longer
  exists in that form — so `ensureSession(forceRefresh: true)` is what makes the
  server agree. Without it the row stays anonymous and the UI keeps offering a
  sign-in already done.
- **`credential-already-in-use` is the player's decision, not ours.** Firebase
  cannot merge two uids. The only way forward abandons the anonymous account's
  progress, so it surfaces as its own outcome and says so in words rather than
  being retried quietly.

**`AuthProvider.Email` had to be added to the backend for this.** Firebase
reports email/password as `"password"`, which mapped to `Unknown`, and a new
user with an unknown provider was stored as `Anonymous` — so an account with a
real email would have been recorded as anonymous while `IsAnonymous` said
otherwise.

**Password reset never reveals whether an address is registered.** The screen
says the same sentence either way; only the log distinguishes them. "No account
with that address" is exactly what somebody probing for registered emails wants.

**Delete account is required by Play** for any app that lets people create
accounts, and it must be reachable in-app rather than only on the web. The
SERVER row goes first and the Firebase identity second: the database is the act
of record, so a failure after it means the data is already gone and the worst
case is an orphaned login that provisions a fresh empty account. Reversed, a
failure destroys the login while the row survives and nobody can ever reach or
delete their own data again.

**Apple is not built yet.** The backend enum already has it, and it becomes
mandatory the moment an iOS build ships with Google on it — App Store review
rejects any app offering a social login without Sign in with Apple.

## Everything account-scoped is scoped to an ACCOUNT

The rule that came out of the September 10 recheck, and the one most likely to
be broken again by an innocent-looking change.

**Linking and switching are different operations.** `linkWithCredential` keeps
the uid, so the session, its token and the local campaign all still belong to
the right player. Signing into an account that already exists REPLACES the uid,
and then every one of those belongs to somebody else. Treating a switch as a
link sent one player's progress under another player's bearer token.

`AuthService.accountEpoch` is how that is enforced. It increments on `forget()`
and on `abandonAccount()`, and anything asynchronous captures it before it
starts and checks it before it writes:

- a sync response for the previous account is DISCARDED, not merged;
- a response that arrives after a deletion cannot resurrect the deleted rows;
- a response computed before a reset cannot undo the reset.

`SyncController.invalidateInFlight()` is the same idea for local causes. The
requests cannot be recalled — they are already with the server — so what
changes is that their answers are dropped on arrival.

**Persisted account state is keyed by uid.** A pending reset stored under a
global key migrated: reset offline, sign in as somebody else, and their first
sync delivered a reset they never asked for.

**Acknowledgements name a revision, not a level.** `_dirty` maps level id to a
revision, and a response only clears entries still at the revision it carried.
Improving a level while its previous result is in flight used to mark the
better run as delivered.

**Resets carry a generation the server recognises.** Serializing the reset
orders it against a concurrent upload but cannot tell obsolete progress from
new play, so a second phone that was offline across the reset put every erased
star back. `User.ProgressResetGeneration` advances on reset; uploads quote the
generation they were recorded under and older ones are refused; a device seeing
a newer generation adopts it by erasing locally and pulling.

**A refund corrects the cached session too.** The session is a snapshot and it
outlives the facts in it: after a refund it still said `adsRemoved: true`, and
the next sync read that stale true and handed the entitlement back.
`AuthService.recordEntitlement` is called by every authoritative change.

**"No session" is not "no account".** Deletion with an unauthenticated session
used to wipe locally, sign out and report success — destroying the credentials
needed to retry while the server account stayed. It now reports
`AccountDeletion.notAuthenticated` and keeps the identity.

**Purchases do NOT depend on any of this.** A Play entitlement belongs to the
Google Play account, not to the Firebase identity: `restorePurchases()` runs on
every launch and the server transfers token ownership to whoever presents it, so
Remove Ads already survives a reinstall and a new phone with nobody signed in.
What sign-in protects is PROGRESS, which has no token to replay. Do not justify
auth work with monetization — the argument is a player on level 96 with a
40-day streak changing phones.

## Secrets

Same rules as the Snake Classic Flutter app. Gitignored, as **globs** rather
than fixed paths so a new flavour or platform folder cannot quietly
reintroduce one:

    **/google-services.json          **/firebase_options.dart
    **/GoogleService-Info.plist       **/.firebaserc
    **/google_service_client_secret.json
    firebase.json                     *.env   (except .env.example)
    **/android/key.properties         *.jks   *.keystore

`firebase_options.dart` was tracked from the first commit before this was
tightened. Adding an ignore rule does NOT untrack a file already in the index
— `git rm --cached` is the other half, and forgetting it is why `firebase.json`
survived a first pass.

**Know which of these are actually secret.** The Firebase files carry the
project id, app id, sender id and Web API key; every one of those values ships
inside the APK and can be read out of any downloaded build. Firebase is
designed that way and relies on Security Rules, App Check and API-key
restrictions instead. They stay out of the repo because an unrestricted Web
API key is worth scraping — it is what drives Identity Toolkit anonymous
sign-up, so it can be burned on quota — not because hiding them provides
security. **Restricting the key in Google Cloud Console is the mitigation that
matters.**

The genuinely secret ones are the keystore and `key.properties`. Losing
control of those means somebody else can sign an update to this app.

## Release signing

The upload keystore lives **only** in `C:\android-keys\pourfect\` — never in
this repository. `android/key.properties` is gitignored and holds an absolute
`storeFile` pointing there, which is the same arrangement Snake Classic uses.

    C:\android-keys\pourfect\
      upload-keystore.jks        the key itself
      key.properties            a copy, so the backup restores on its own
      keystore-credentials.txt  passwords, alias, DN, creation date
      upload_certificate.pem    the public certificate

Certificate matches the other projects: `CN=PRANTA Dutta, OU=Pranta's Apps,
O=Dutta Corp, L=Chattogram, ST=Chattogram, C=BD`, RSA 2048, SHA384withRSA,
10,000 days. Alias `upload`.

Gradle falls back to debug keys with a loud warning when `key.properties` is
absent, so a fresh clone still builds — but a debug-signed build **cannot be
uploaded to Play**, which is why the fallback is noisy rather than silent.

**Verify what actually signed a build** rather than assuming:

    apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

The SHA-256 must match `upload_certificate.pem`. Confirmed once already:
`dedb09a7…0922b6`.

**THIS KEY IS THE APP'S IDENTITY FOREVER.** Play accepts updates signed by it
and nothing else, so losing it means the listing can never be updated again —
a new listing, and every install starts from zero. Back up
`C:\android-keys\` somewhere that is not this machine.

**`.env` is bundled into the APK as a Flutter asset.** Gitignoring it is repo
hygiene, NOT secrecy — anyone can unzip a build and read it. Public
identifiers and endpoint URLs only: `GOOGLE_WEB_CLIENT_ID`,
`DEV_API_BACKEND_URL`, `PROD_API_BACKEND_URL`. Never a signing key, a service
account, or an API secret.

`.claude/` IS tracked on purpose, to share project knowledge across devices —
never put credentials in it.

To audit at any time:

    git ls-files | grep -iE "google-services|firebase_options|\.env|keystore|\.jks"

Only `.env.example` should come back.
