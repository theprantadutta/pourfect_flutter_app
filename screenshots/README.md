# Screenshots

Captured from a debug build on the dev Samsung A24 (1080x2340), 2026-09-17.

These are **not** the Play Store listing assets — they carry a debug build's
state and a real account's handle. They exist so a change to a screen can be
argued about against what the screen actually looks like, rather than against
a description of it.

| File | What |
|---|---|
| `01_home.png` | The hub: crest, wordmark, stat row, board preview, Continue, the challenge clock, the campaign path |
| `02_gameplay.png` | A board at move 0 |
| `03_gameplay_selected.png` | A run held. The source tube is ringed in accent and every illegal destination is dimmed to 40% |
| `04_campaign_path.png` | The path scrolled forward, showing unplayed levels and a band label |
| `05_daily_challenge.png` | Today's board, generated server-side |
| `06_leaderboard.png` | Campaign tab. `Teal_Decant_8762` is a server-generated name, not a typed one |
| `07_statistics.png` | Lifetime and Against the clock |
| `08_statistics_levels.png` | By section, and the per-level table |
| `09_settings.png` | Player header, Feel, Visibility with the palette strip |
| `10_settings_lower.png` | The lower sections and the danger zone |
| `11_account.png` | What the crest opens when signed in |
| `12_account_lower.png` | The rest of it, down to Sign out |
| `13_rename.png` | The rename box, pre-filled and selected, with the length counter |
| `14_win_moment.png` | Mid-choreography: the last ball landing, the completed tube glowing |
| `15_win_settled.png` | The win settled. Three stars, NEW BEST, 7% under par, band track, Next level |

## How they were taken

`adb`, driving the app directly. Two things are worth knowing before repeating it:

- **`input swipe x y x y 120`, not `input tap`.** A synthesised tap is too short
  for `Pressable` to register, and the first event after a screen change is
  frequently swallowed.
- **The campaign path scrolls in reverse.** Dragging DOWN moves forward through
  the campaign, because the path climbs. Costs a few minutes if you assume
  otherwise.

`14` and `15` are a real solve of level 2 in 5 moves, which is par: T1 -> T4,
T2 -> T1, T2 -> T4, T3 -> T4, T2 -> T3. Par on a level whose previous best was 6
is a three-star personal best, which is what earns `WinProfile.full` rather than
the brief one -- so the screenshot is the full choreography, not the short one.
