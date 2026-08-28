# Pourfect — Play Store listing (draft)

Written for **organic search and browse**, which is the only acquisition channel
we have. Two audiences read this text and they are not the same:

- **Play's indexing**, which reads the title and short description hardest.
- **A human scanning ten identical-looking sort games**, who reads the first two
  lines of the full description and nothing else unless those two lines earn it.

So the keywords are placed where they are indexed, and the prose is written so a
person who is tired of ads and unsolvable levels recognizes themselves in it.

---

## Title — 30 characters max

```
Pourfect: Ball Sort Puzzle
```
**25 / 30.** Brand first so the name is searchable once anyone hears it, then the
two highest-volume category terms. "Ball Sort" and "Puzzle" are what people
actually type; the colon is conventional in this genre and costs nothing.

*Alternate if we want "color" in the title instead of the brand tail:*
```
Pourfect: Color Sort Puzzle
```
**26 / 30.** Pick ONE and leave it alone — Play re-indexes on change and the
early ranking signal is worth more than the A/B.

---

## Short description — 80 characters max

```
Relaxing ball sort puzzle. Play offline, no wifi needed. Every level solvable.
```
**77 / 80.**

Three claims, each doing a different job:

- **"Relaxing"** — the emotional promise, and the differentiator against the
  frantic, ad-heavy end of the category.
- **"Play offline, no wifi needed"** — carries both offline keywords in natural
  language. This is a genuine competitive advantage and a real search term;
  people look for games that work on a plane and on the underground.
- **"Every level solvable"** — the single most common one-star complaint in this
  genre, answered before it is asked. We can say it because a solver proved it.

---

## Full description — 4000 characters max

```
A calm color sorting puzzle you can play anywhere.

Pour the balls between tubes until each one holds a single color. That's the
whole game. No timers, no lives, no waiting to play again.


NO WIFI? NO PROBLEM.

Pourfect works completely offline. Every level is already on your phone, so it
plays the same on a plane, on the underground, or with one bar of signal.


EVERY LEVEL CAN BE SOLVED

This is the part most sorting games get wrong. Every one of our 150 levels was
checked by a solver before it shipped, and we know the fewest moves each one
takes. You will never hit a level that simply cannot be finished.


BUILT TO BE RELAXING

- Unlimited undo, always free. Change your mind as often as you like.
- No timers and no lives. Put it down mid-level and come back tomorrow.
- A hint when you want one, never nagging you to take it.
- Soft sounds and gentle haptics you can turn off in one tap.


PLAYS NICELY WITH YOUR MUSIC

Pourfect mixes with whatever you are already listening to. It will never pause
your podcast or your playlist to play a sound effect.


DESIGNED TO BE SEEN CLEARLY

Every ball carries a distinct shape as well as a color, so the game stays
playable if you are color blind. It isn't a mode you have to find in a menu —
it's how the game is drawn. There's a bold-symbols setting if you want the
shapes larger still.


150 LEVELS THAT ACTUALLY BUILD

- First Pours — three and four colors, gentle enough to learn on.
- Finding Rhythm — five to seven colors, where it starts to click.
- Deep Water — eight to ten colors, real puzzles now.
- Mastery — ten colors and only one spare tube. Room for nothing sloppy.

The difficulty was tuned level by level, with easier levels deliberately placed
along the way so it never becomes a grind.


SMALL, QUIET, RESPECTFUL

Under 25 MB. No account required. No forced ads between every level. Nothing
here is trying to trick you into a purchase.


Pour, sort, relax.
```

**≈1,780 / 4000.**

### Why it is written this way

- **The first line is the whole pitch.** Play truncates the description behind a
  "more" link, so the first two lines have to carry it alone. Everything after
  is for the minority who tap through.
- **Keywords appear in sentences, not in a list.** A comma-separated keyword
  dump reads as spam to a person and Play has discounted them for years. "ball
  sort", "color sorting", "offline", "no wifi", "puzzle", "color blind" all
  appear in prose that a human would actually say.
- **Headers are shouty capitals, not emoji.** Emoji bullets are the house style
  of exactly the games we are differentiating from.
- **Every claim is true and checkable.** "Every level can be solved" is a
  solver-proven invariant, "under 25 MB" is measured per-ABI, "mixes with your
  music" is a verified audio-session policy. Nothing here needs walking back.

---

## Before this goes live

- [x] **US English throughout.** Settled: "color", not "colour" — "color sort"
      carries materially more search volume. Swept across the listing, every
      in-app string, and the whole codebase (319 occurrences), so nothing can
      drift back.
- [ ] **Privacy policy URL — CONFIRM THE DOMAIN.** `pourfect.pranta.dev/privacy`
      is a placeholder **I invented**, not a URL anyone has confirmed exists.
      Pick the real one and the swap is a single line: `kPrivacyPolicyUrl` in
      `lib/ui/screens/settings_screen.dart`. The page itself is written and
      ready to host at `generated/privacy_policy.html`.
      It must be LIVE before the listing can be published — Play rejects a dead
      link, and the same URL goes in the Play Console listing field, so it has
      to match what Settings opens.
- [ ] **Screenshots** — the single highest-leverage asset on the page, more than
      any of this text. Lead with the board mid-pour, then the win moment, then
      the level map. Do NOT lead with a menu.
- [ ] **Feature graphic** (1024×500). Board on the ink ground, no text over it.
- [ ] **Data safety form** — we collect analytics; that must be declared.
- [ ] Re-check the character counts after any edit. Play silently truncates.
