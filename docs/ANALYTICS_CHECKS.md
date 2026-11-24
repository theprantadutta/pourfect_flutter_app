# What to check, and where

Written 2026-11-24 with release 2.8.0+20. Only RELEASE builds report, so
nothing below includes testers running debug builds. Google Analytics
property: 551875472 (open it from Firebase → Analytics → "View more in
Google Analytics").

## 1. Are people finding the game? (Play Console)

Grow users → overview, last 28 days. Numbers on 2026-11-24, before the
changes below went live:

| Step | Baseline |
|---|---|
| Device impressions | 13,000 (99% Google Play explore) |
| Store listing visitors | 160 (about 1.2% of impressions) |
| Install clicks | 13 (8% of visitors) |
| Ratings | 1 (5★), 0 reviews |

**What changed, and when:**
- **2026-11-24:** new English description (no more "No timers"), plus
  pt-BR, es-419 and tr-TR listings. Watch visitors from Brazil, Mexico and
  Türkiye in Statistics → by country.
- **2026-11-24:** icon experiment, current icon vs "A" (three tubes), 50/50.
  Store listings → Default store listing → Experiments. Expect no
  statistically significant result at this traffic. Compare install clicks
  per visitor for each arm instead.
- **2.8.0:** the rating card is asked for more often (see 3). Watch the
  rating count on Ratings and reviews → Ratings.

## 2. Where do players drop off? (GA → Reports → Engagement → Events)

Use the **Level** dimension (text), NOT "Level ID": GA would not fill the
number-valued one. Level only exists on events from 2.8.0 onward.

- `level_start`, `level_complete`, `level_abandon` with secondary dimension
  **Level**, filtered to **Play mode** = `campaign`. For each level:
  completes ÷ starts is its pass rate. A low pass rate means a level that
  loses players.
- `level_abandon` with **Abandon reason**: `backgrounded` (left the app),
  `exited`, `restarted`.
- `level_complete` with **Star count**: how many clear at par.
- `tutorial_begin` vs `tutorial_complete`: tutorial drop-off. The baseline
  was 20 begun, 15 finished.
- Custom metrics **Abandon progress** (0 to 1) and **Level duration**
  (seconds) on those events.

One player in Zimbabwe produced 2,800 `undo_used` events in November. Look
at undo per user, not totals.

## 3. Is the rating ask working? (GA)

`review_prompt` with parameter `placement`: `hub` (back on the home screen)
or `next_level` (the break after NEXT, new in 2.8.0). Register `placement`
if it is missing (it already is, as the "Placement" dimension). Compare
asks against new ratings in Play Console. Play doesn't report whether the
card actually appeared.

## 4. Retention (Firebase → Analytics → Dashboard / Retention)

The baseline was about 7% of new users back in week 1. User properties to
split by: `levels_solved` (bands of ten), `ads_removed`, `account`.

## 5. Stability and money

- **Crashlytics** (Firebase): no crashes on Android as of 2026-11-24.
- **AdMob** (app overview): $0.19 in November, eCPM rewarded ~$18 and
  interstitial ~$5.7. Ad revenue also shows in GA through the AdMob link
  (`ad_impression`).
- **Purchases:** `iap_purchased` carries `value` and `currency`. Store
  revenue comes from Firebase's automatic `in_app_purchase`.
