// Board layout is pure geometry, so it can be checked without a device — which
// matters, because the failure mode is a tube clipped off the edge of a phone
// and that is only visible on a screenshot of the exact level that triggers it.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/ui/widgets/board_geometry.dart';

/// Screen widths, minus the board's horizontal padding, across the range of
/// Android phones this has to run on.
const _widths = <double>[300, 320, 345, 360, 392, 411, 440];

void main() {
  group('the board always fits', () {
    test('no tube ever crosses the left or right edge', () {
      // The bug this pins: padding is a function of ball size, so solving the
      // fit with a fixed padding guess under-computes tube width and the last
      // tube in a row hangs off the screen. It clipped level 150.
      for (final width in _widths) {
        for (var tubes = 3; tubes <= 14; tubes++) {
          final geometry = BoardGeometry.fit(
            available: Size(width, 520),
            tubeCount: tubes,
            capacity: 4,
          );

          for (var i = 0; i < geometry.tubeRects.length; i++) {
            final rect = geometry.tubeRects[i];
            expect(
              rect.left,
              greaterThanOrEqualTo(-0.01),
              reason: 'tube $i of $tubes overflows left at width $width',
            );
            expect(
              rect.right,
              lessThanOrEqualTo(width + 0.01),
              reason: 'tube $i of $tubes overflows right at width $width',
            );
          }
        }
      }
    });

    test('every tube is laid out', () {
      for (var tubes = 3; tubes <= 14; tubes++) {
        final geometry = BoardGeometry.fit(
          available: const Size(360, 520),
          tubeCount: tubes,
          capacity: 4,
        );
        expect(geometry.tubeRects, hasLength(tubes));
      }
    });

    test('tubes in a row never overlap', () {
      for (final width in _widths) {
        final geometry = BoardGeometry.fit(
          available: Size(width, 520),
          tubeCount: 12,
          capacity: 4,
        );
        final rects = geometry.tubeRects;
        for (var i = 1; i < rects.length; i++) {
          final a = rects[i - 1];
          final b = rects[i];
          if ((a.top - b.top).abs() > 1) continue; // different row
          expect(
            b.left,
            greaterThanOrEqualTo(a.right - 0.01),
            reason: 'tubes $i and ${i - 1} overlap at width $width',
          );
        }
      }
    });

    test('balls fit inside their tube', () {
      final geometry = BoardGeometry.fit(
        available: const Size(360, 520),
        tubeCount: 12,
        capacity: 4,
      );
      for (var tube = 0; tube < geometry.tubeCount; tube++) {
        final rect = geometry.tubeRects[tube];
        for (var slot = 0; slot < geometry.capacity; slot++) {
          final centre = geometry.ballCentre(tube, slot);
          expect(
            centre.dx - geometry.ballSize / 2,
            greaterThanOrEqualTo(rect.left - 0.01),
          );
          expect(
            centre.dx + geometry.ballSize / 2,
            lessThanOrEqualTo(rect.right + 0.01),
          );
          expect(
            centre.dy - geometry.ballSize / 2,
            greaterThanOrEqualTo(rect.top - 0.01),
          );
          expect(
            centre.dy + geometry.ballSize / 2,
            lessThanOrEqualTo(rect.bottom + 0.01),
          );
        }
      }
    });

    test('the board fits its vertical space', () {
      for (var tubes = 3; tubes <= 14; tubes++) {
        const height = 520.0;
        final geometry = BoardGeometry.fit(
          available: const Size(360, height),
          tubeCount: tubes,
          capacity: 4,
        );
        for (final rect in geometry.tubeRects) {
          expect(rect.bottom, lessThanOrEqualTo(height + 0.01));
        }
      }
    });

    test('a lifted ball never rises above the board area', () {
      // The lift point is where a selected run hovers. If it goes negative the
      // held run clips into the HUD.
      for (var tubes = 3; tubes <= 14; tubes++) {
        final geometry = BoardGeometry.fit(
          available: const Size(360, 520),
          tubeCount: tubes,
          capacity: 4,
        );
        for (var tube = 0; tube < geometry.tubeCount; tube++) {
          final lift = geometry.liftPoint(tube);
          expect(
            lift.dy - geometry.ballSize / 2,
            greaterThanOrEqualTo(-0.01),
            reason: 'the lift clips the top at $tubes tubes',
          );
        }
      }
    });

    test('balls stay big enough to tell apart', () {
      // Below roughly 22dp the accessibility glyphs stop being legible, which
      // would quietly undo the whole palette exercise.
      for (final width in _widths) {
        final geometry = BoardGeometry.fit(
          available: Size(width, 520),
          tubeCount: 12,
          capacity: 4,
        );
        expect(geometry.ballSize, greaterThanOrEqualTo(22));
      }
    });
  });

  group('tap targets', () {
    test('a tap inside a tube resolves to that tube', () {
      final geometry = BoardGeometry.fit(
        available: const Size(360, 520),
        tubeCount: 11,
        capacity: 4,
      );
      for (var tube = 0; tube < geometry.tubeCount; tube++) {
        expect(geometry.tubeAt(geometry.tubeRects[tube].center), tube);
      }
    });

    test('a tap in empty space resolves to nothing', () {
      final geometry = BoardGeometry.fit(
        available: const Size(360, 520),
        tubeCount: 5,
        capacity: 4,
      );
      expect(geometry.tubeAt(const Offset(180, 500)), isNull);
    });
  });
}
