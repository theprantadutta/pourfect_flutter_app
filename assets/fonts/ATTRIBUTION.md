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

## Manrope — DROP THESE IN

Download from <https://fonts.google.com/specimen/Manrope> → **Get font** →
**Download all**. The zip contains a variable font and a `static/` folder;
**use the `static/` files**, not the variable one — Flutter's weight matching is
far more predictable with discrete files.

Copy exactly these four into this folder, keeping the filenames:

| File | Weight | Used for |
|---|---|---|
| `Manrope-Regular.ttf` | 400 | body copy, setting descriptions |
| `Manrope-Medium.ttf` | 500 | secondary labels |
| `Manrope-SemiBold.ttf` | 600 | HUD labels, section headers, button text |
| `Manrope-Bold.ttf` | 700 | screen titles, the primary action |

Roughly 55 KB each, so about **220 KB** total — against a 20.8 MB arm64 build.

### Then make these two changes

**1. `pubspec.yaml`** — add the family alongside the existing one, under the
same `fonts:` key:

```yaml
  fonts:
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Medium.ttf
          weight: 500
        - asset: assets/fonts/JetBrainsMono-Bold.ttf
          weight: 700
    - family: Manrope
      fonts:
        - asset: assets/fonts/Manrope-Regular.ttf
          weight: 400
        - asset: assets/fonts/Manrope-Medium.ttf
          weight: 500
        - asset: assets/fonts/Manrope-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Manrope-Bold.ttf
          weight: 700
```

**2. `lib/ui/theme/typography.dart`** — one line:

```dart
const String? kUiFontFamily = 'Manrope';
```

Everything downstream reads that constant, so nothing else needs touching.

---

## Licence text — REQUIRED BEFORE RELEASE

The OFL-1.1 requires the full licence text to ship with the app. Put both files
in `assets/licenses/`, named exactly:

- `assets/licenses/OFL-JetBrainsMono.txt` — from
  <https://github.com/JetBrains/JetBrainsMono/blob/master/OFL.txt>
- `assets/licenses/OFL-Manrope.txt` — the `OFL.txt` inside the Google Fonts zip

That directory is already declared in `pubspec.yaml` and
`lib/services/licenses.dart` already registers whatever it finds there, so the
text appears under **Settings → About → Licences** in the standard Flutter
licence page. Nothing else is needed: drop the files in and they are picked up.

If a file is missing the app still runs — the registration fails quietly rather
than crashing — but **do not ship without them.**
