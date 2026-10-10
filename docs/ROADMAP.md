# Pourfect feature roadmap

Written 2026-10-10 after a gameplay audit. Eleven features, **built in the order
listed**: each one is ranked by what it does for retention and revenue against
what it costs, and some later items reuse earlier ones.

This file is meant to be handed to any agent. Read the "Before you start"
section first, then pick the first item whose status is not `done`.

---

## Before you start (every agent, every item)

**Repos**

| Path | What |
|---|---|
| `pourfect_flutter_app/` | the game (Flutter, Riverpod). Read its `CLAUDE.md` first: it is long and it is law. |
| `pourfect-dotnet-api/` | the API (.NET 10 Clean Architecture, MediatR `Result<T>`, EF Core snake_case, Hangfire on Redis). Read its `CLAUDE.md`. |
| `pourfect-dotnet-api/dashboard/` | the admin dashboard (Next.js 15 server components). Read its `README.md`. |

**Rules that apply to every item**

- **Layering:** `engine/` (pure Dart) → `state/` → `ui/`. Check with
  `dart run tool/check_layering.dart`. Game logic never lives in `ui/`.
- **Providers:** manual Riverpod providers only (no codegen).
- **Look:** use the Toybox look: `Toy.*` helpers, `Toy.tabletScale`,
  `Toy.maxContentWidth`, and `showToyToast` for messages. There is no
  Scaffold-level SnackBar, so never use one. Every screen must look right on
  BOTH the phone and the tablet.
- **Server is the authority** for progress, points, the daily and the
  leaderboard.
  - `Scoring.IsPlausible` rejects any move count under a level's proven
    optimum (`minMoves`).
  - Never submit a fabricated count below it. See `GameState.recordedMoves`
    for how assisted clears are handled.
- **Undo is free and unlimited.** No feature may charge for undo or limit it.
- **No banner ads.**
  - Rewarded videos are opt-in, always behind a confirm prompt
    (`_confirmWatchAd`), with the clock paused while the prompt and the video
    are up.
  - Any new rewarded placement goes in `RewardedPlacement`
    (`lib/services/ads/ad_service.dart`) and must be `isReachable`.
- **Notifications:** at most 2 a day and 6 hours apart (see
  `NotificationRules` in the API). Do not add a notification kind without
  asking the owner.
- **Analytics:** log new actions through the existing analytics service so the
  dashboard can show them.
- **Before calling an item done**, run:
  - `dart analyze`
  - the layering check
  - `flutter test`
  - the API tests (`dotnet test`) if the API changed
  - `npm run build` in `dashboard/` if the dashboard changed
- **Devices:** the test phone is a Samsung A24 (`RR8W901JDRL`). Another agent
  may be using it, so ask before driving it. Use the tablet (`R83X309RLNR`)
  only when the owner asks.
- **Git:**
  - Commit or push only when the owner asks.
  - Commit messages never mention Claude, Anthropic or any model name, and
    never carry a Co-Authored-By line or similar.
  - Do a minor version bump in `pubspec.yaml` only when asked.
- **Product calls belong to the owner.** If a choice changes how the game
  plays or earns money (prices, caps, star rules), ask rather than guess.

**Already in place, so don't rebuild it**

| Area | What exists |
|---|---|
| Scoring | stars from `starsFor` (`lib/engine/level.dart`); points and the level clock |
| Help | hints (`lib/state/hint_controller.dart`, with `PositionAnalyst` solving every position in the background); paid dead-end answers |
| Extra tube | up to 2 per attempt; offered when stuck, in a dead end, or past par; assisted clear 2★ max |
| Daily Pour | `daily_controller.dart`; the server already returns `daily_streak` (`lib/services/api/daily_api.dart`) |
| Leaderboard | yes |
| Stats | `play_history.dart` already tracks days played and the longest streak |
| Feel | audio (`lib/services/audio/`, SoLoud plus a synth) and haptics (`lib/services/haptics/`) |
| Notifications | full system plus the dashboard page |
| Money | Remove Ads IAP |
| Content | server-generated level packs beyond the bundled 150 |

---

## 1. Streaks and the Daily Pour calendar

**Status:** not started
**Why:** the strongest return-tomorrow hook, and most of the data exists.

**Build**
1. **Show the streak.** A streak flame and count on the home screen and the
   daily screen, using the server's `daily_streak`. Don't compute it on the
   device.
2. **Month calendar** on the daily screen. Each day is stamped as played,
   missed or frozen. It needs an endpoint (or an extension of the daily one)
   that returns the player's daily results for a month.
3. **Streak freeze.**
   - Holding: at most one, kept on the server (`streak_freezes` on the player).
     Earned once a week, or by watching a rewarded video. The video is a new
     `RewardedPlacement.streakFreeze` behind the usual confirm prompt.
   - Spending: a missed day is filled automatically if a freeze is held, when
     the server computes the streak.
   - Server work: an EF migration plus a change to the streak calculation in
     the daily handler.
4. **Milestones:** a celebration when the streak reaches 3, 7, 14, 30 and 100
   days, using the existing win-celebration style.
5. **Dashboard:** show the streak and freezes on the player page, and the
   streak spread on the Overview.

**Done when:** the streak shows on both screens, a freeze saves a missed day
end to end against the local API, the API tests cover the freeze rule, and the
dashboard shows it.

**Ask the owner:** how freezes are earned (weekly, by video, or both), and the
maximum held.

---

## 2. "Try for 3★" on the win screen

**Status:** not started
**Why:** an instant replay, with zero new content.

**Build**
1. On a clear with fewer than 3★, the win card says
   **"Par N, you took M. Try for 3★?"** and offers a button that restarts
   straight away (the same path as the existing restart).
2. Only for unassisted clears. If `extraTubeUsed`, say that 3★ needs a clear
   without the extra tube.
3. Log `retry_for_stars` and record whether the retry earned 3★.

**Done when:** a widget test covers the copy for a 2★ clear and an assisted
clear, the button restarts the same level, and the screen is checked on both
phone and tablet.

---

## 3. Star chests on the journey

**Status:** not started
**Why:** it gives stars a use, and the "double it" video is a natural ad slot.

**Build**
1. **Engine.** Thresholds in `engine/`: one chest every 30 stars. The rewards
   are fixed by threshold, so they are reproducible, not random.
2. **Rewards:** hint credits, extra-tube credits (both already exist in
   `monetization_controller.dart`), and later the cosmetics from item 4.
3. **Server.** Opened chests are stored on the server (`opened_chests`), so
   they cannot be opened twice across devices. Opening is a server call that
   returns the reward.
4. **UI.** Chest markers on `journey_screen.dart`, then an opening animation in
   the Toybox style.
5. **Optional "double it" video:** `RewardedPlacement.chestDouble`.
6. **Dashboard:** chests opened per player.

**Done when:** a chest opens once per account across two devices, credits
land, and there are tests for the threshold maths and the server's
idempotency.

**Ask the owner:** the reward table and the threshold spacing.

---

## 4. Cosmetics: ball skins and tube themes

**Status:** not started. It depends on item 3 for unlocks.
**Why:** the main way to earn money in this genre without pay-to-win.

**Build**
1. **Skins.** A `BallSkin` / `TubeTheme` catalogue in `ui/theme/`:
   - Each skin keeps the colour-blind glyphs. A skin only restyles, it never
     removes the glyphs.
   - Start with 3 skins and 2 tube themes.
2. **Unlock sources:** stars or chests, a streak milestone, or included with
   Remove Ads. Possibly a separate IAP later.
3. **Storage.** Owned and equipped items are stored on the server, and the
   equipped ones are cached locally so the board never flashes the default.
4. **Picker** in Settings or a new Collection screen, with a live preview
   board.
5. **Screenshot check:** the store screenshots still match the default skin.

**Done when:** equipping a skin changes the board, the win screen and the
daily screen; colour-blind glyphs still show; and the equipped skin survives a
reinstall after signing in.

**Ask the owner:** which skins are free and which are paid, and the price if
an IAP.

---

## 5. Hard and Super-hard levels

**Status:** not started
**Why:** spikes in the difficulty curve feel good, and it is mostly labelling.

**Build**
1. In `engine/level_curve.dart` / `difficulty.dart`, mark every 10th level
   (or the top difficulty scores in each band) as `hard`, and the band peak as
   `superHard`.
   - Changing the generated content means bumping `kLevelSetVersion` and
     rebuilding `levels.bin` (see the app's `CLAUDE.md`).
   - Prefer labelling existing levels over regenerating them.
2. Add a badge on the journey and the HUD, and a different board backdrop.
3. A points multiplier for hard levels. This needs the matching change on the
   server, or the points disagree.
4. Generated server packs need the same flag in their payload.

**Done when:** the labels are deterministic (tested), client and server
points agree (tested on both sides), and it is checked on both devices.

**Ask the owner:** the multiplier, and whether to keep the label only or also
use a harder generation.

---

## 6. Dead-end marker in the undo history

**Status:** not started
**Why:** it teaches without spending a hint, and it is cheap because the
solver already knows.

**Build**
1. When `PositionAnalyst` proves the current board is a dead end, find the
   last board in `undoStack` that is still solvable. `stepsBackToSolvable`
   already does this.
2. Show a subtle marker: a small dot on the Undo button with the number of
   steps. Don't show a toast, and don't reveal the move.
3. **Decide with the owner whether this undercuts the paid dead-end hint**,
   which says the same thing. If it does, show only "this position can't be
   finished" and keep the step count behind the hint.

**Done when:** the owner has decided point 3, and there is a widget test for
the marker appearing on a proven dead end.

---

## 7. Weekly event

**Status:** not started
**Why:** a shared goal for everybody, built on the leaderboard and the level
clock.

**Build**
1. **Server.** Each Monday a Hangfire job picks 7 generated levels, seeded by
   the week. Store them with their own leaderboard: points from the existing
   scoring, total across the 7.
2. **Endpoints:** the week's levels, submitting a result (with the same
   plausibility checks), and the event leaderboard.
3. **App.** An event card on home, an event screen with 7 tiles, and a
   countdown to the reset. Results count for the event only, not the campaign.
4. **Dashboard:** an event page (levels, entrants, the board), and a "generate
   now" button like the existing System page.
5. **Optional:** a new notification kind for "the event ends tomorrow". Ask
   first. It counts toward the 2-a-day cap.

**Done when:** a week can be generated, played, submitted and ranked end to
end against the local API, with API tests for the weekly seed and the
submission checks.

---

## 8. Achievements

**Status:** not started
**Why:** cheap goals that last, and good dashboard material.

**Build**
1. Achievements are a catalogue in `state/`. Each is evaluated from progress
   and play history. Examples:
   - 10 levels at exactly par
   - a clear with no undo
   - a clear under 30 seconds
   - 7-day streak
   - all 3★ in a world
2. **Unlocks.** Store them on the server; the server re-checks what it can.
   Show a toast on unlock with `showToyToast`.
3. **Screen.** An Achievements screen from Statistics, with locked and
   unlocked states.
4. **Dashboard:** unlock rates per achievement.

**Done when:** each achievement has a unit test for its condition, and
unlocks sync across devices.

---

## 9. Gameplay sound and haptics polish

**Status:** not started
**Why:** the look is already strong; feel is the cheapest upgrade left.

**What exists today:** `AudioService` (`lib/services/audio/audio_service.dart`)
has six cues, all synthesized at runtime in `synth.dart` and played through
SoLoud: `pour(fill)`, `select`, `tubeComplete`, `star(i)`, `win`, `newBest`.
There are no audio files in `assets/`.

**Build:** this is a polish pass on those cues and `services/haptics/`. The
app-wide work is item 11. Do not add a new audio package.
1. Make `tubeComplete` hit harder, and give it a matching haptic.
2. Rising pitch on pours made in a quick run.
3. A clear final-pour beat that leads into the `win` cue.
4. Respect the existing mute and haptics settings, and system silent mode.
5. Check on the A24. Cheap phones distort loud low-end sounds.

**Done when:** the owner has listened on the phone and is happy, and there are
no audio regressions in the tests.

---

## 10. Zen mode after the campaign

**Status:** not started
**Why:** keeps the players who finish everything.

**Build**
1. Unlocks after the campaign and the generated packs are finished, or
   optionally from the start.
2. Endless levels from the existing generator at a chosen difficulty band,
   generated on the device off-thread, like the solver.
3. No clock, no stars, no leaderboard. Only a count of boards poured.
4. Interstitials follow the existing persisted caps. Hints and tubes work as
   in the campaign.
5. A Zen entry on home, and a short "Zen" label in the HUD.

**Done when:** a 50-board session has no repeated boards and no jank (check
frame pacing on the A24), and the caps are respected.

---

## 11. Sound design across the whole app

**Status:** not started. Do it after item 9, which settles the gameplay
sound palette this item extends.
**Why:** today only the board makes sound. Menus, buttons, the journey, the
daily screen, toasts, chests and celebrations are silent, and music would
give the game an identity.

**Build**
1. **Sound palette.** Write it up in this file before any code: one
   instrument family and one key, so every cue sounds like the same game. It
   should be playful and glassy to match Toybox, with short attacks and
   nothing harsh. Get the owner's approval on the palette first.
2. **UI cues.** Add them to `AudioService`, the `Recording` test fake and both
   implementations:
   - `tap` for buttons, via the Toy button widgets so every button gets it
     with no per-screen code
   - `toggle` for switches
   - `back` / navigate
   - `sheetOpen` / `sheetClose`
   - `toast`
   - `error` (soft, never alarming)
   - `rewardGranted` for when a video pays out
   - `undo`
   - `hint` reveal
   - `extraTube` appearing
   - `streak`, `chestOpen` and `achievement` for items 1, 3 and 8
3. **Music.** One calm, looping track for menus and a softer, quieter variant
   for gameplay, crossfaded between them.
   - Source: synthesized, or a properly licensed file. Record the licence in
     `assets/licenses` and in `lib/services/licenses.dart`.
   - Ducking: dip the music under the `win` and `star` cues.
   - Interruptions: pause on app background and on audio focus loss, using
     the existing `audio_session` setup.
4. **Settings.** Separate **Sound effects** and **Music** switches, each with
   a volume slider, replacing the single mute if that is what exists. Respect
   system silent or vibrate mode. Music starts off for new installs until the
   owner decides otherwise.
5. **Mixing.**
   - Nothing clips when cues overlap (a pour, a tube completing and a star in
     one frame).
   - A cap on concurrent voices.
   - Quick repeats of the same cue (fast tapping) are rate-limited.
6. **Performance.**
   - Load or synthesize all cues once at start-up, off the first frame (the
     splash handoff must not stutter).
   - Check frame pacing on the A24 with music playing.
   - Keep the APK size reasonable; prefer synthesis or short OGG files.
7. **Analytics.** Log whether sound and music are on, so the dashboard can
   show how many players keep them.

**Done when:**
- every cue in point 2 exists and is wired;
- the `Recording` fake asserts the important ones in widget tests (tap on a
  Toy button, undo, reward granted);
- the music loops without a gap and pauses in the background;
- the settings persist;
- the owner has listened on the A24 and approved.

**Ask the owner:** the palette and mood, whether to have music at all and
whether it defaults to on, and a synthesized versus licensed track.

---

## Status log

Each agent that finishes an item updates its **Status** line above and adds a
line here: date, item, what shipped, anything left over.

- 2026-10-10: roadmap written. Shipped before it: a paid dead-end hint, and an
  extra tube offered when stuck (up to 2 per attempt, assisted clear 2★ max).
