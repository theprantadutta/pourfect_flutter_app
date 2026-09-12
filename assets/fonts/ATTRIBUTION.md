# Bundled fonts

Both faces are **bundled**, never fetched. `google_fonts` exists for runtime
fetching, which we deliberately do not do: the game must be fully playable
offline, and a face that pops in on first launch looks broken.

---

## JetBrains Mono — present

Copyright 2020 The JetBrains Mono Project Authors.
SIL Open Font License 1.1 · <https://github.com/JetBrains/JetBrainsMono>

Carries every numeral in the game — move counts, level numbers, band counts.
Chosen for even color at 11px and a slashed zero, so `0` and `O` never trade
places on a leaderboard.

| File | Weight |
|---|---|
| `JetBrainsMono-Medium.ttf` | 500 |
| `JetBrainsMono-Bold.ttf` | 700 |

---

## Manrope — present

Copyright 2018 The Manrope Project Authors.
SIL Open Font License 1.1 · <https://github.com/sharanda/manrope>

The UI face: titles, labels, body copy, buttons. Carries everything that is not
a numeral. A geometric sans with a tall x-height, which holds up at the 11px
label size without the tracking having to do all the work.

Static weights, not the variable font. Flutter's weight matching is far more
predictable with discrete files, and a variable axis it cannot address is dead
bytes against the APK budget.

| File | Weight | Used for |
|---|---|---|
| `Manrope-Regular.ttf` | 400 | body copy, setting descriptions |
| `Manrope-Medium.ttf` | 500 | secondary labels |
| `Manrope-SemiBold.ttf` | 600 | HUD labels, section headers, button text |
| `Manrope-Bold.ttf` | 700 | screen titles, the primary action |

---

## Licence texts

Both OFL-1.1 texts are in `assets/licenses/`, registered at startup by
`lib/services/licenses.dart` and shown on the app's licence page. The OFL
obliges us to ship them; shipping the fonts without them is a licence breach,
not a tidiness issue.
