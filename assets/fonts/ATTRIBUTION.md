# Bundled fonts

## JetBrains Mono
Copyright 2020 The JetBrains Mono Project Authors.
Licensed under the SIL Open Font License, Version 1.1.
Source: https://github.com/JetBrains/JetBrainsMono

Used for every numeral in the game — move counts, level numbers, band counts,
timers. Chosen for even colour at 11px and a slashed zero, so 0 and O never
trade places on a leaderboard.

TODO BEFORE RELEASE: the OFL-1.1 requires the full licence text to ship with
the app. Drop `OFL.txt` from the JetBrains Mono repository into this folder and
register it in `main.dart` via `LicenseRegistry.addLicense`.

## Manrope — NOT YET BUNDLED
Chosen for the UI face but not present on the build machine. Until the TTFs are
added here, `kUiFontFamily` stays null and the UI uses the platform face
(Roboto on Android). Add `Manrope-Medium/SemiBold/Bold/ExtraBold.ttf`, then set
`kUiFontFamily = 'Manrope'` in `lib/ui/theme/typography.dart` and declare the
family in `pubspec.yaml` alongside JetBrains Mono.
