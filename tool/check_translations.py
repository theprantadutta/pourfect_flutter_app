"""Checks lib/l10n/src/<locale>/*.arb against English before gen-l10n runs.

  python -I tool/check_translations.py ru       (one locale)
  python -I tool/check_translations.py          (all)

For every translated message it checks:
  - the key exists in English (a typo there is a string that never shows);
  - the same set of {placeholders} appears (renaming one breaks the build,
    dropping one loses the number from the sentence);
  - braces balance, so ICU plural/select syntax isn't broken;
  - plural messages keep an `other` branch (ICU requires it).
It also lists English keys with no translation (they fall back to English).
"""

import glob
import json
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib", "l10n", "src")


def load(locale):
    out = {}
    for path in sorted(glob.glob(os.path.join(ROOT, locale, "*.arb"))):
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        for k, v in data.items():
            if not k.startswith("@"):
                out[k] = (v, os.path.basename(path))
    return out


def top_level_placeholders(text):
    """Placeholder names, ignoring the text inside plural/select branches."""
    names = set()
    depth = 0
    i = 0
    while i < len(text):
        c = text[i]
        if c == "{":
            if depth == 0:
                m = re.match(r"\{\s*([A-Za-z_][A-Za-z0-9_]*)", text[i:])
                if m:
                    names.add(m.group(1))
            depth += 1
        elif c == "}":
            depth -= 1
        i += 1
    return names


def braces_ok(text):
    depth = 0
    for c in text:
        depth += c == "{"
        depth -= c == "}"
        if depth < 0:
            return False
    return depth == 0


def check(locale, english):
    problems, translated = [], load(locale)
    for key, (text, file) in translated.items():
        if key not in english:
            problems.append(f"{file}: {key}: not in English")
            continue
        en = english[key][0]
        if not braces_ok(text):
            problems.append(f"{file}: {key}: unbalanced braces")
            continue
        if top_level_placeholders(text) != top_level_placeholders(en):
            problems.append(
                f"{file}: {key}: placeholders {sorted(top_level_placeholders(text))}"
                f" != English {sorted(top_level_placeholders(en))}")
        if re.search(r",\s*plural\s*,", text) and not re.search(r"\bother\s*\{", text):
            problems.append(f"{file}: {key}: plural without an 'other' branch")
        # gen-l10n compiles "=1{...}" to the "one" CATEGORY. Where that
        # category is wider than the number 1, the =1 text leaks: Portuguese
        # "one" is 0 and 1 (a fresh board read "1 jogada"), Russian and
        # Ukrainian "one" is 1, 21, 31...
        lang = locale.split("_")[0]
        if "=1{" in text:
            if lang == "pt" and "=0{" not in text:
                problems.append(f"{file}: {key}: =1 needs a =0 branch in {lang} ('one' includes 0)")
            if lang in ("ru", "uk", "be") and not re.search(r"\bone\s*\{", text):
                problems.append(f"{file}: {key}: =1 needs a one{{}} branch in {lang} ('one' includes 21, 31...)")
    missing = sorted(set(english) - set(translated))
    return problems, missing


def main():
    english = load("en")
    locales = sys.argv[1:] or sorted(
        d for d in os.listdir(ROOT) if d != "en" and os.path.isdir(os.path.join(ROOT, d)))
    failed = False
    for locale in locales:
        problems, missing = check(locale, english)
        print(f"{locale}: {len(english) - len(missing)}/{len(english)} translated,"
              f" {len(problems)} problems")
        for p in problems:
            print("  " + p)
        if missing:
            print(f"  untranslated ({len(missing)}): " + ", ".join(missing[:20])
                  + (" ..." if len(missing) > 20 else ""))
        failed |= bool(problems)
    sys.exit(1 if failed else 0)


main()
