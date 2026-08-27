/// The shipped campaign: a versioned, ordered set of levels plus its binary
/// codec.
///
/// UI-IMPORTABLE — data and serialization only, no game decisions.
///
/// The asset is BINARY rather than JSON because the payload is almost entirely
/// small integers: 150 levels of tube contents cost about 11 KB packed against
/// roughly 200 KB as JSON, and the APK budget is 25 MB total.
library;

import 'dart:typed_data';

import 'board.dart';
import 'level.dart';

/// File magic. Guards against loading a truncated or unrelated asset and
/// interpreting garbage as a board.
const List<int> kLevelSetMagic = [0x50, 0x46, 0x4C, 0x56]; // 'PFLV'

/// Version of the BINARY LAYOUT below. Bump when the byte format changes.
///
/// Distinct from [LevelSet.levelSetVersion], which versions the CONTENT. A
/// format bump is a code-compatibility concern; a content bump is a
/// player-progress concern.
const int kLevelSetFormatVersion = 1;

/// A campaign level: a [Level] plus where it sits in the curve.
///
/// Band and breather membership are baked into the asset rather than recomputed
/// at load, so the validator, the curve report and the level-select UI all read
/// one source of truth.
final class CampaignLevel {
  final Level level;

  /// Index into the campaign's band list.
  final int bandIndex;

  /// True for deliberate easier levels placed every ~10 to break the climb.
  final bool isBreather;

  const CampaignLevel({
    required this.level,
    required this.bandIndex,
    required this.isBreather,
  });

  int get id => level.id;

  @override
  String toString() =>
      'CampaignLevel(${level.id}, band $bandIndex'
      '${isBreather ? ", breather" : ""})';
}

/// A complete, ordered campaign.
final class LevelSet {
  /// CONTENT version of this campaign.
  ///
  /// Stored alongside every `LevelProgress` row, locally and on the server, so
  /// a saved star rating always records which board it was earned against.
  ///
  /// v1 ships no migration logic and does not need any. The field exists
  /// because it CANNOT be retrofitted: without it, changing or reordering a
  /// single level after launch silently repoints every player's saved progress
  /// at a different board — their 3-star on level 87 would now claim to be a
  /// 3-star on a level they have never seen, and the server's anti-cheat floor
  /// would be comparing against the wrong `minMoves`. Cheap now, impossible
  /// later.
  final int levelSetVersion;

  /// Levels in campaign order, ids 1..n.
  final List<CampaignLevel> levels;

  const LevelSet({required this.levelSetVersion, required this.levels});

  int get length => levels.length;

  CampaignLevel operator [](int index) => levels[index];

  /// Looks up by 1-based campaign id.
  CampaignLevel? byId(int id) {
    for (final l in levels) {
      if (l.id == id) return l;
    }
    return null;
  }

  @override
  String toString() => 'LevelSet(v$levelSetVersion, ${levels.length} levels)';
}

/// Binary encoder/decoder for [LevelSet].
///
/// Fixed big-endian layout, no padding, no floating point on the wire — the
/// asset must be reproducible BYTE-FOR-BYTE from a seed, so nothing here may
/// depend on platform endianness or float formatting.
///
/// ```
/// header  magic[4] formatVersion:u8 levelSetVersion:u16 levelCount:u16
/// level   id:u16 bandIndex:u8 flags:u8 capacity:u8 tubeCount:u8
///         minMoves:u16 difficultyScore:u16 forcedMoveRatio:u16
///         tube*   ballCount:u8 colour:u8 * ballCount
/// ```
abstract final class LevelSetCodec {
  /// Fixed-point scale for `difficultyScore` (0-100 → 0-10000).
  static const int scoreScale = 100;

  /// Fixed-point scale for `forcedMoveRatio` (0-1 → 0-10000).
  static const int ratioScale = 10000;

  static Uint8List encode(LevelSet set) {
    final out = BytesBuilder(copy: false);
    final header = ByteData(9);
    for (var i = 0; i < 4; i++) {
      header.setUint8(i, kLevelSetMagic[i]);
    }
    header.setUint8(4, kLevelSetFormatVersion);
    header.setUint16(5, set.levelSetVersion);
    header.setUint16(7, set.levels.length);
    out.add(header.buffer.asUint8List());

    for (final campaign in set.levels) {
      final level = campaign.level;
      final board = level.board;

      final fixed = ByteData(12);
      fixed.setUint16(0, level.id);
      fixed.setUint8(2, campaign.bandIndex);
      fixed.setUint8(3, campaign.isBreather ? 1 : 0);
      fixed.setUint8(4, board.capacity);
      fixed.setUint8(5, board.tubeCount);
      fixed.setUint16(6, level.minMoves);
      fixed.setUint16(8, _quantise(level.difficultyScore, scoreScale));
      fixed.setUint16(10, _quantise(level.forcedMoveRatio, ratioScale));
      out.add(fixed.buffer.asUint8List());

      for (final tube in board.tubes) {
        out.addByte(tube.length);
        for (final colour in tube.balls) {
          out.addByte(colour);
        }
      }
    }

    return out.takeBytes();
  }

  static LevelSet decode(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    var offset = 0;

    for (var i = 0; i < 4; i++) {
      if (data.getUint8(offset + i) != kLevelSetMagic[i]) {
        throw const FormatException('not a Pourfect level set (bad magic)');
      }
    }
    offset += 4;

    final formatVersion = data.getUint8(offset++);
    if (formatVersion != kLevelSetFormatVersion) {
      throw FormatException(
        'level set format v$formatVersion, this build reads '
        'v$kLevelSetFormatVersion',
      );
    }

    final levelSetVersion = data.getUint16(offset);
    offset += 2;
    final count = data.getUint16(offset);
    offset += 2;

    final levels = <CampaignLevel>[];
    for (var i = 0; i < count; i++) {
      final id = data.getUint16(offset);
      final bandIndex = data.getUint8(offset + 2);
      final isBreather = data.getUint8(offset + 3) == 1;
      final capacity = data.getUint8(offset + 4);
      final tubeCount = data.getUint8(offset + 5);
      final minMoves = data.getUint16(offset + 6);
      final score = data.getUint16(offset + 8) / scoreScale;
      final forced = data.getUint16(offset + 10) / ratioScale;
      offset += 12;

      final tubes = <List<ColorId>>[];
      for (var t = 0; t < tubeCount; t++) {
        final ballCount = data.getUint8(offset++);
        tubes.add([
          for (var b = 0; b < ballCount; b++) data.getUint8(offset + b),
        ]);
        offset += ballCount;
      }

      levels.add(
        CampaignLevel(
          level: Level(
            id: id,
            board: Board.fromLists(tubes, capacity: capacity),
            minMoves: minMoves,
            difficultyScore: score,
            forcedMoveRatio: forced,
          ),
          bandIndex: bandIndex,
          isBreather: isBreather,
        ),
      );
    }

    return LevelSet(levelSetVersion: levelSetVersion, levels: levels);
  }

  /// Rounds a value onto the wire's fixed-point grid.
  ///
  /// Encoding is lossy by design — two decimal places on a score nobody ever
  /// sees is plenty. Callers that need `encode(decode(x)) == x` should build
  /// their levels from already-quantised values; [quantiseLevel] does that.
  static int _quantise(double value, int scale) => (value * scale).round();

  /// Snaps a level's score and ratio onto the wire grid.
  ///
  /// Used by the generator so the in-memory campaign and the decoded asset hold
  /// identical numbers — otherwise a re-encode of a decoded set could differ in
  /// the last bit and break byte-for-byte reproducibility.
  static Level quantiseLevel(Level level) => Level(
    id: level.id,
    board: level.board,
    minMoves: level.minMoves,
    difficultyScore: _quantise(level.difficultyScore, scoreScale) / scoreScale,
    forcedMoveRatio: _quantise(level.forcedMoveRatio, ratioScale) / ratioScale,
  );
}
