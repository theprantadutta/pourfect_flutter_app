# Bundled fonts

Both faces are **bundled**, never fetched. `google_fonts` exists for runtime
fetching, which we deliberately do not do: the game must be fully playable
offline, and a face that pops in on first launch looks broken.

---

## Bagel Fat One — present

Copyright 2022 The Bagel Fat Project Authors.
SIL Open Font License 1.1 · <https://github.com/JAMO-TYPEFACE/BagelFat>

The display face: the Ball-O wordmark, screen titles, big numbers and CTA
labels. One weight; the ink drop shadow is what gives it its sticker weight.

**Subset to Latin.** The upstream file carries Hangul and weighs 1.58 MB; the
bundled one is 52 KB. Re-subset from the Google Fonts TTF with:

    python -m fontTools.subset BagelFatOne-Regular.ttf \
      --unicodes="U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,U+20AC,U+2122,U+2190-2199,U+2212,U+2215,U+2605-2606,U+25B6,U+25BC" \
      --layout-features='*' --output-file=BagelFatOne-Regular.ttf

The OFL permits this; a subset is a Modified Version and keeps the licence.

| File | Weight |
|---|---|
| `BagelFatOne-Regular.ttf` | 400 |

---

## Outfit — present

Copyright 2021 The Outfit Project Authors.
SIL Open Font License 1.1 · <https://github.com/Outfitio/Outfit-Fonts>

The UI face: labels, body copy, buttons, and every number — with
`FontFeature.tabularFigures()` so counters do not shift as they tick.

Static weights, not the variable font. Flutter's weight matching is far more
predictable with discrete files.

| File | Weight | Used for |
|---|---|---|
| `Outfit-Medium.ttf` | 500 | body copy, row details |
| `Outfit-SemiBold.ttf` | 600 | captions, subtitles |
| `Outfit-Bold.ttf` | 700 | row titles, chips |
| `Outfit-ExtraBold.ttf` | 800 | buttons, caps labels, numbers |

---

## Licence texts

Both OFL-1.1 texts are in `assets/licenses/`, registered at startup by
`lib/services/licenses.dart` and shown on the app's licence page. The OFL
obliges us to ship them; shipping the fonts without them is a licence breach,
not a tidiness issue.
