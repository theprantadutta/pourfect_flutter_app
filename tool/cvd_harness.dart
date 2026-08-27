// Colour-blindness proof sheet for the ball palette.
//
//   dart run tool/cvd_harness.dart
//   -> generated/cvd_harness.html
//
// Run this BEFORE committing any palette change, and re-run it before raising
// the colour ceiling. Ten simultaneous colours is already at the edge of what
// stays separable, and a palette that looks fine to a trichromat can be
// unplayable for the ~8% of men with a colour vision deficiency — in this genre
// that is the single most common accessibility complaint in store reviews.
//
// WHAT THIS ACTUALLY CHECKS. Not "do the colours look different" — under
// dichromacy ten muted colours CANNOT all be strongly separable, and pretending
// otherwise would be the whole failure. It checks two things instead:
//
//   1. How much work colour still does, per pair, per deficiency (CIEDE2000).
//   2. Whether the pairs colour FAILS on are carried by their glyphs — two
//      near-identical colours must not also have near-identical silhouettes.
//
// A pair that is weak on colour AND weak on shape is a hard failure. That is
// the pair a player cannot resolve at all, and the tool exits non-zero on it.

import 'dart:io';
import 'dart:math' as math;

import 'package:pourfect_flutter_app/ui/theme/ball_palette.dart';

const _outputPath = 'generated/cvd_harness.html';

/// Below this CIEDE2000 distance, colour is doing little useful work and the
/// glyph has to carry the pair. ~10 is roughly "obvious at a glance for a small
/// object", well above the ~2.3 just-noticeable threshold for large flat areas.
const double _weakColourDelta = 10;

/// Ball diameter in logical pixels, matching the board at 10-12 tubes on a
/// typical phone. Everything is drawn at this size so the sheet shows the
/// problem as a player meets it, not blown up to where it disappears.
const double _ballSizeDp = 28;

void main(List<String> args) {
  final sims = <String, List<double>>{
    'Normal': _identity,
    'Protanopia': _protanopia,
    'Deuteranopia': _deuteranopia,
    'Tritanopia': _tritanopia,
  };

  final report = StringBuffer();
  final hardFailures = <String>[];
  final results = <String, List<_Pair>>{};

  for (final entry in sims.entries) {
    final simulated = [
      for (final style in kBallPalette) _simulate(style.rgb, entry.value),
    ];

    final pairs = <_Pair>[];
    for (var i = 0; i < kBallPalette.length; i++) {
      for (var j = i + 1; j < kBallPalette.length; j++) {
        pairs.add(
          _Pair(
            a: i,
            b: j,
            delta: _ciede2000(_labOf(simulated[i]), _labOf(simulated[j])),
            glyphsAlike:
                _glyphGroup(kBallPalette[i].glyph) ==
                _glyphGroup(kBallPalette[j].glyph),
          ),
        );
      }
    }
    pairs.sort((x, y) => x.delta.compareTo(y.delta));
    results[entry.key] = pairs;

    for (final pair in pairs) {
      if (pair.delta < _weakColourDelta && pair.glyphsAlike) {
        hardFailures.add(
          '${entry.key}: ${kBallPalette[pair.a].name} vs '
          '${kBallPalette[pair.b].name} — colour ΔE '
          '${pair.delta.toStringAsFixed(1)} AND similar glyph silhouettes '
          '(${kBallPalette[pair.a].glyph.name}/'
          '${kBallPalette[pair.b].glyph.name})',
        );
      }
    }

    final weak = pairs.where((p) => p.delta < _weakColourDelta).length;
    report.writeln(
      '${entry.key.padRight(14)} min ΔE ${pairs.first.delta.toStringAsFixed(1).padLeft(5)}   '
      'median ${pairs[pairs.length ~/ 2].delta.toStringAsFixed(1).padLeft(5)}   '
      '$weak/${pairs.length} pairs rely on glyph',
    );
  }

  stdout
    ..writeln('Ball palette — ${kBallPalette.length} colours\n')
    ..write(report.toString());

  _write(_outputPath, _buildHtml(sims, results, hardFailures));
  stdout.writeln('\nwrote $_outputPath');

  if (hardFailures.isNotEmpty) {
    stderr.writeln('\n${hardFailures.length} HARD FAILURE(S):\n');
    for (final failure in hardFailures) {
      stderr.writeln('  - $failure');
    }
    stderr.writeln(
      '\nA pair weak on BOTH colour and shape is unresolvable. Change one of '
      'the two colours, or give one of them a glyph from a different '
      'silhouette group.',
    );
    exit(1);
  }
  stdout.writeln('\nNo pair is weak on both colour and shape.');
}

// ---------------------------------------------------------------------------
// Colour-vision simulation
//
// Machado, Oliveira & Fernandes (2009) severity-1.0 matrices. Applied in LINEAR
// RGB — running them on gamma-encoded sRGB is a common shortcut that noticeably
// misstates the result, which would defeat the point of measuring at all.
// ---------------------------------------------------------------------------

const _identity = <double>[1, 0, 0, 0, 1, 0, 0, 0, 1];

const _protanopia = <double>[
  0.152286, 1.052583, -0.204868, //
  0.114503, 0.786281, 0.099216, //
  -0.003882, -0.048116, 1.051998,
];

const _deuteranopia = <double>[
  0.367322, 0.860646, -0.227968, //
  0.280085, 0.672501, 0.047413, //
  -0.011820, 0.042940, 0.968881,
];

const _tritanopia = <double>[
  1.255528, -0.076749, -0.178779, //
  -0.078411, 0.930809, 0.147602, //
  0.004733, 0.691367, 0.303900,
];

int _simulate(int rgb, List<double> m) {
  final r = _toLinear(((rgb >> 16) & 0xFF) / 255);
  final g = _toLinear(((rgb >> 8) & 0xFF) / 255);
  final b = _toLinear((rgb & 0xFF) / 255);

  final sr = m[0] * r + m[1] * g + m[2] * b;
  final sg = m[3] * r + m[4] * g + m[5] * b;
  final sb = m[6] * r + m[7] * g + m[8] * b;

  return (_toSrgbByte(sr) << 16) | (_toSrgbByte(sg) << 8) | _toSrgbByte(sb);
}

double _toLinear(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

int _toSrgbByte(double linear) {
  final c = linear.clamp(0.0, 1.0);
  final encoded = c <= 0.0031308
      ? c * 12.92
      : 1.055 * math.pow(c, 1 / 2.4).toDouble() - 0.055;
  return (encoded * 255).round().clamp(0, 255);
}

// ---------------------------------------------------------------------------
// CIELAB + CIEDE2000
// ---------------------------------------------------------------------------

List<double> _labOf(int rgb) {
  final r = _toLinear(((rgb >> 16) & 0xFF) / 255);
  final g = _toLinear(((rgb >> 8) & 0xFF) / 255);
  final b = _toLinear((rgb & 0xFF) / 255);

  final x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047;
  final y = (0.2126729 * r + 0.7151522 * g + 0.0721750 * b) / 1.0;
  final z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883;

  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : (7.787 * t) + (16 / 116);

  return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
}

/// CIEDE2000 colour difference. Worth the length over the simpler CIE76: at the
/// small separations this palette lives at, CIE76 badly overstates differences
/// in the blue region, which is exactly where several of these balls sit.
double _ciede2000(List<double> lab1, List<double> lab2) {
  const kL = 1.0, kC = 1.0, kH = 1.0;
  final l1 = lab1[0], a1 = lab1[1], b1 = lab1[2];
  final l2 = lab2[0], a2 = lab2[1], b2 = lab2[2];

  final c1 = math.sqrt(a1 * a1 + b1 * b1);
  final c2 = math.sqrt(a2 * a2 + b2 * b2);
  final cBar = (c1 + c2) / 2;

  final cBar7 = math.pow(cBar, 7).toDouble();
  final g = 0.5 * (1 - math.sqrt(cBar7 / (cBar7 + math.pow(25, 7))));

  final a1p = (1 + g) * a1;
  final a2p = (1 + g) * a2;
  final c1p = math.sqrt(a1p * a1p + b1 * b1);
  final c2p = math.sqrt(a2p * a2p + b2 * b2);

  double hue(double a, double b) {
    if (a == 0 && b == 0) return 0;
    final h = math.atan2(b, a) * 180 / math.pi;
    return h >= 0 ? h : h + 360;
  }

  final h1p = hue(a1p, b1);
  final h2p = hue(a2p, b2);

  final dLp = l2 - l1;
  final dCp = c2p - c1p;

  double dhp;
  if (c1p * c2p == 0) {
    dhp = 0;
  } else if ((h2p - h1p).abs() <= 180) {
    dhp = h2p - h1p;
  } else if (h2p - h1p > 180) {
    dhp = h2p - h1p - 360;
  } else {
    dhp = h2p - h1p + 360;
  }
  final dHp = 2 * math.sqrt(c1p * c2p) * math.sin(dhp * math.pi / 360);

  final lBarP = (l1 + l2) / 2;
  final cBarP = (c1p + c2p) / 2;

  double hBarP;
  if (c1p * c2p == 0) {
    hBarP = h1p + h2p;
  } else if ((h1p - h2p).abs() <= 180) {
    hBarP = (h1p + h2p) / 2;
  } else if (h1p + h2p < 360) {
    hBarP = (h1p + h2p + 360) / 2;
  } else {
    hBarP = (h1p + h2p - 360) / 2;
  }

  final t =
      1 -
      0.17 * math.cos((hBarP - 30) * math.pi / 180) +
      0.24 * math.cos((2 * hBarP) * math.pi / 180) +
      0.32 * math.cos((3 * hBarP + 6) * math.pi / 180) -
      0.20 * math.cos((4 * hBarP - 63) * math.pi / 180);

  final dTheta = 30 * math.exp(-math.pow((hBarP - 275) / 25, 2).toDouble());
  final cBarP7 = math.pow(cBarP, 7).toDouble();
  final rc = 2 * math.sqrt(cBarP7 / (cBarP7 + math.pow(25, 7)));
  final rt = -rc * math.sin(2 * dTheta * math.pi / 180);

  final lBarP50 = math.pow(lBarP - 50, 2).toDouble();
  final sl = 1 + (0.015 * lBarP50) / math.sqrt(20 + lBarP50);
  final sc = 1 + 0.045 * cBarP;
  final sh = 1 + 0.015 * cBarP * t;

  final termL = dLp / (kL * sl);
  final termC = dCp / (kC * sc);
  final termH = dHp / (kH * sh);

  return math.sqrt(
    termL * termL + termC * termC + termH * termH + rt * termC * termH,
  );
}

// ---------------------------------------------------------------------------
// Glyph silhouette grouping
// ---------------------------------------------------------------------------

/// Coarse silhouette family. Two glyphs in the same family read as similar at
/// ball size, so a colour pair that is weak under simulation must not also
/// share one.
String _glyphGroup(BallGlyph glyph) => switch (glyph) {
  BallGlyph.dot || BallGlyph.ring || BallGlyph.hexagon => 'round',
  BallGlyph.triangle || BallGlyph.diamond => 'pointed',
  BallGlyph.square || BallGlyph.bar => 'blocky',
  BallGlyph.plus || BallGlyph.cross => 'strokes',
  BallGlyph.arc => 'arc',
};

// ---------------------------------------------------------------------------
// HTML proof sheet
// ---------------------------------------------------------------------------

String _buildHtml(
  Map<String, List<double>> sims,
  Map<String, List<_Pair>> results,
  List<String> hardFailures,
) {
  final body = StringBuffer();

  body.writeln('''
<h1>Pourfect ball palette</h1>
<p class="lede">Ten colours, each paired with a distinct shape glyph, shown at
${_ballSizeDp.toInt()}dp — the size a ball actually renders at on a 10-tube
board. Colour is never the only cue: under dichromacy ten muted colours cannot
all stay separable, so the glyph carries the pairs colour loses.</p>
''');

  if (hardFailures.isEmpty) {
    body.writeln(
      '<p class="verdict pass">No pair is weak on both colour and shape.</p>',
    );
  } else {
    body.writeln(
      '<div class="verdict fail"><strong>'
      '${hardFailures.length} hard failure(s)</strong><ul>',
    );
    for (final f in hardFailures) {
      body.writeln('<li>${_escape(f)}</li>');
    }
    body.writeln('</ul></div>');
  }

  for (final entry in sims.entries) {
    final name = entry.key;
    final pairs = results[name]!;
    final simulated = [
      for (final style in kBallPalette) _simulate(style.rgb, entry.value),
    ];

    body.writeln('<section><h2>$name</h2>');

    // Balls on the real surface colour, at real size.
    body.writeln('<div class="board">');
    for (var i = 0; i < kBallPalette.length; i++) {
      body.writeln(_ballSvg(simulated[i], kBallPalette[i].glyph, _ballSizeDp));
    }
    body.writeln('</div>');

    // Magnified, for judging the glyphs themselves.
    body.writeln('<div class="board magnified">');
    for (var i = 0; i < kBallPalette.length; i++) {
      body.writeln(
        _ballSvg(simulated[i], kBallPalette[i].glyph, _ballSizeDp * 2.5),
      );
    }
    body.writeln('</div>');

    body.writeln('<div class="names">');
    for (var i = 0; i < kBallPalette.length; i++) {
      body.writeln(
        '<span><b>${kBallPalette[i].name}</b>'
        '${kBallPalette[i].glyph.name}</span>',
      );
    }
    body.writeln('</div>');

    final weak = pairs.where((p) => p.delta < _weakColourDelta).toList();
    body.writeln(
      '<p class="stat">min ΔE <b>${pairs.first.delta.toStringAsFixed(1)}</b>'
      ' · median <b>${pairs[pairs.length ~/ 2].delta.toStringAsFixed(1)}</b>'
      ' · <b>${weak.length}</b> of ${pairs.length} pairs rely on the glyph</p>',
    );

    if (weak.isNotEmpty) {
      body.writeln('<table><tr><th>pair</th><th>ΔE</th><th>glyphs</th></tr>');
      for (final pair in weak.take(12)) {
        final a = kBallPalette[pair.a];
        final b = kBallPalette[pair.b];
        body.writeln(
          '<tr class="${pair.glyphsAlike ? "bad" : ""}">'
          '<td>${a.name} / ${b.name}</td>'
          '<td>${pair.delta.toStringAsFixed(1)}</td>'
          '<td>${a.glyph.name} vs ${b.glyph.name}'
          '${pair.glyphsAlike ? " — SAME FAMILY" : ""}</td></tr>',
        );
      }
      body.writeln('</table>');
    }
    body.writeln('</section>');
  }

  return '''
<!doctype html>
<html><head><meta charset="utf-8">
<title>Pourfect ball palette — colour vision proof sheet</title>
<style>
  :root { color-scheme: dark; }
  body {
    margin: 0; padding: 40px;
    background: ${_css(kSurfaceRgb)};
    color: #E8EAF0;
    font: 15px/1.6 ui-sans-serif, system-ui, -apple-system, sans-serif;
  }
  h1 { font-size: 26px; font-weight: 600; margin: 0 0 8px; letter-spacing: -.01em; }
  h2 { font-size: 15px; font-weight: 600; margin: 0 0 16px;
       text-transform: uppercase; letter-spacing: .08em; color: #9AA3B4; }
  .lede { max-width: 60ch; color: #9AA3B4; margin: 0 0 24px; }
  .verdict { padding: 12px 16px; border-radius: 8px; margin: 0 0 32px;
             border: 1px solid; }
  .verdict.pass { border-color: #2C5B4A; background: #12271F; color: #7FD4AE; }
  .verdict.fail { border-color: #6B2F35; background: #2A1417; color: #E8929B; }
  .verdict ul { margin: 8px 0 0; padding-left: 20px; }
  section { margin: 0 0 44px; padding: 24px;
            background: ${_css(kSurfaceRaisedRgb)};
            border: 1px solid #232937; border-radius: 12px; }
  .board { display: flex; gap: 10px; align-items: center; flex-wrap: wrap;
           padding: 16px; background: ${_css(kSurfaceRgb)};
           border-radius: 8px; margin-bottom: 12px; }
  .board.magnified { gap: 16px; }
  .names { display: flex; gap: 10px; flex-wrap: wrap; margin: 10px 0 0; }
  .names span { flex: 1 1 0; min-width: 70px; font-size: 11px; color: #6D7688; }
  .names b { display: block; color: #C3CAD8; font-weight: 600; }
  .stat { color: #9AA3B4; font-size: 13px; margin: 16px 0 8px; }
  .stat b { color: #E8EAF0; font-variant-numeric: tabular-nums; }
  table { border-collapse: collapse; width: 100%; font-size: 13px;
          font-variant-numeric: tabular-nums; }
  th { text-align: left; color: #6D7688; font-weight: 500; padding: 6px 10px;
       border-bottom: 1px solid #232937; font-size: 11px;
       text-transform: uppercase; letter-spacing: .06em; }
  td { padding: 6px 10px; border-bottom: 1px solid #1B202B; color: #C3CAD8; }
  tr.bad td { color: #E8929B; }
</style></head>
<body>$body</body></html>
''';
}

/// One ball: a filled circle with its glyph drawn on top.
///
/// The glyph is drawn in a translucent dark ink rather than a fixed colour, so
/// it stays legible on both the palest and the deepest balls without needing a
/// per-colour override.
String _ballSvg(int rgb, BallGlyph glyph, double size) {
  const vb = 100.0;
  const c = vb / 2;
  final ink = 'rgba(10,12,16,.72)';
  final stroke =
      'stroke="$ink" stroke-width="9" fill="none" '
      'stroke-linecap="round" stroke-linejoin="round"';

  final shape = switch (glyph) {
    BallGlyph.dot => '<circle cx="$c" cy="$c" r="13" fill="$ink"/>',
    BallGlyph.ring => '<circle cx="$c" cy="$c" r="17" $stroke/>',
    BallGlyph.triangle => '<path d="M50 30 L69 64 L31 64 Z" fill="$ink"/>',
    BallGlyph.square =>
      '<rect x="33" y="33" width="34" height="34" rx="3" '
          'fill="$ink"/>',
    BallGlyph.plus => '<path d="M50 30 V70 M30 50 H70" $stroke/>',
    BallGlyph.bar =>
      '<rect x="28" y="43" width="44" height="14" rx="7" '
          'fill="$ink"/>',
    BallGlyph.diamond =>
      '<path d="M50 28 L70 50 L50 72 L30 50 Z" fill="$ink"/>',
    BallGlyph.cross => '<path d="M35 35 L65 65 M65 35 L35 65" $stroke/>',
    BallGlyph.arc => '<path d="M30 62 A24 24 0 0 1 70 62" $stroke/>',
    BallGlyph.hexagon =>
      '<path d="M50 28 L69 39 L69 61 L50 72 L31 61 L31 39 Z" $stroke/>',
  };

  return '<svg width="${size.toStringAsFixed(0)}" '
      'height="${size.toStringAsFixed(0)}" viewBox="0 0 100 100">'
      '<circle cx="$c" cy="$c" r="48" fill="${_css(rgb)}"/>'
      '$shape</svg>';
}

String _css(int rgb) => '#${rgb.toRadixString(16).padLeft(6, '0')}';

String _escape(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

void _write(String path, String contents) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents.replaceAll('\r\n', '\n'));
}

final class _Pair {
  final int a;
  final int b;
  final double delta;
  final bool glyphsAlike;

  const _Pair({
    required this.a,
    required this.b,
    required this.delta,
    required this.glyphsAlike,
  });
}
