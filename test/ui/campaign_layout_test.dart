// Every shipped level must LAY OUT on every phone we target.
//
// Solvability is already proven by the engine suite and re-proven by
// tool/validate_levels.dart. This is the other half of "playable": a level can
// be perfectly solvable and still unplayable because a tube hangs off the edge
// of the screen or the balls shrink past the point where the accessibility
// glyphs read. That failure is invisible to every test that does not know the
// screen width, and it shipped once already on level 150.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/engine/level_set.dart';
import 'package:pourfect_flutter_app/ui/widgets/board_geometry.dart';

/// Board area, in logical pixels, across the Android range we target — screen
/// width minus the board's horizontal padding, and screen height minus the HUD
/// and the control row.
const _screens = <(String, Size)>[
  ('small 5.0" 320dp', Size(272, 380)),
  ('common 5.5" 360dp', Size(312, 440)),
  ('Pixel-class 393dp', Size(345, 500)),
  ('large 411dp', Size(363, 560)),
  ('tablet-ish 600dp', Size(552, 700)),
];

void main() {
  final set = LevelSetCodec.decode(
    File('assets/levels/levels.bin').readAsBytesSync(),
  );

  test('the campaign is the size we think it is', () {
    expect(set.length, 150);
  });

  for (final (name, area) in _screens) {
    group('on $name', () {
      test('every level fits without clipping', () {
        for (final campaignLevel in set.levels) {
          final board = campaignLevel.level.board;
          final geometry = BoardGeometry.fit(
            available: area,
            tubeCount: board.tubeCount,
            capacity: board.capacity,
          );

          expect(
            geometry.tubeRects,
            hasLength(board.tubeCount),
            reason: 'level ${campaignLevel.id} lost a tube',
          );

          for (var i = 0; i < geometry.tubeRects.length; i++) {
            final rect = geometry.tubeRects[i];
            expect(
              rect.left >= -0.01 &&
                  rect.right <= area.width + 0.01 &&
                  rect.bottom <= area.height + 0.01,
              isTrue,
              reason:
                  'level ${campaignLevel.id} (${board.tubeCount} tubes) '
                  'clips at tube $i: $rect in $area',
            );
          }
        }
      });

      test('balls never shrink below glyph legibility', () {
        // Below roughly 20dp the shape on a ball stops being tellable apart,
        // which would quietly undo the whole color-blindness exercise.
        for (final campaignLevel in set.levels) {
          final board = campaignLevel.level.board;
          final geometry = BoardGeometry.fit(
            available: area,
            tubeCount: board.tubeCount,
            capacity: board.capacity,
          );
          expect(
            geometry.ballSize,
            greaterThanOrEqualTo(20),
            reason:
                'level ${campaignLevel.id} renders ${geometry.ballSize}dp '
                'balls on $name',
          );
        }
      });

      test('a held run never clips above the board', () {
        for (final campaignLevel in set.levels) {
          final board = campaignLevel.level.board;
          final geometry = BoardGeometry.fit(
            available: area,
            tubeCount: board.tubeCount,
            capacity: board.capacity,
          );
          for (var tube = 0; tube < geometry.tubeCount; tube++) {
            expect(
              geometry.liftPoint(tube).dy - geometry.ballSize / 2,
              greaterThanOrEqualTo(-0.01),
              reason: 'level ${campaignLevel.id} lift clips the HUD',
            );
          }
        }
      });
    });
  }

  test('the hardest band really is the shape we designed', () {
    // Guards the stage-6 decision: the last stretch steps up by REMOVING an
    // empty tube, not by adding colors past the accessibility cap.
    final mastery = set.levels.where((l) => l.id >= 121);
    expect(mastery, hasLength(30));

    for (final level in mastery) {
      expect(level.level.colorCount, lessThanOrEqualTo(10));
    }
    expect(
      mastery.where((l) => l.level.emptyTubeCount == 1),
      isNotEmpty,
      reason: 'no single-empty-tube levels survived the bake',
    );
  });
}
