/// Star chests on the server: which are earned, which are open.
///
/// Opening is the server's to allow, because a chest must open once per
/// ACCOUNT, not once per phone. What a chest holds is fixed by its index, and
/// the server says it back so the two can never disagree.
library;

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'api_result.dart';

@immutable
class ChestStatus {
  /// The server's star total. Can trail the device's until a sync lands.
  final int totalStars;
  final int starsPerChest;

  /// Opened chests by index, and whether each was doubled by a video.
  final Map<int, bool> opened;

  const ChestStatus({
    required this.totalStars,
    required this.starsPerChest,
    required this.opened,
  });

  static ChestStatus? fromJson(Map<String, Object?> body) {
    final per = (body['stars_per_chest'] as num?)?.toInt();
    if (per == null || per <= 0) return null;
    return ChestStatus(
      totalStars: (body['total_stars'] as num?)?.toInt() ?? 0,
      starsPerChest: per,
      opened: {
        for (final row in body['opened'] as List? ?? const [])
          if (row is Map && row['index'] is num)
            (row['index'] as num).toInt(): row['doubled'] == true,
      },
    );
  }
}

/// What opening or doubling a chest just granted.
@immutable
class ChestReward {
  final int index;
  final int hints;
  final int extraTubes;

  /// Every third chest also unlocks a cosmetic.
  final bool cosmetic;

  /// True for the credits a video added on top.
  final bool doubled;

  /// The ball skin or tube theme this chest unlocked, if any.
  final String? cosmeticId;

  const ChestReward({
    required this.index,
    required this.hints,
    required this.extraTubes,
    required this.cosmetic,
    required this.doubled,
    this.cosmeticId,
  });

  static ChestReward fromJson(Map<String, Object?> body) => ChestReward(
    index: (body['index'] as num?)?.toInt() ?? 0,
    hints: (body['hints'] as num?)?.toInt() ?? 0,
    extraTubes: (body['extra_tubes'] as num?)?.toInt() ?? 0,
    cosmetic: body['cosmetic'] == true,
    doubled: body['doubled'] == true,
    cosmeticId: body['cosmetic_id'] as String?,
  );
}

class ChestApi {
  final ApiClient _client;

  const ChestApi(this._client);

  Future<ApiResult<ChestStatus>> status() async {
    final response = await _client.get('/api/v1/chests');
    return switch (response) {
      ApiOk(:final value) => switch (ChestStatus.fromJson(value)) {
        final status? => ApiOk(status),
        null => const ApiFailure(
          ApiFailureKind.server,
          detail: 'chests were malformed',
        ),
      },
      ApiFailure(:final kind, :final detail, :final statusCode) => ApiFailure(
        kind,
        detail: detail,
        statusCode: statusCode,
      ),
    };
  }

  Future<ApiResult<ChestReward>> open(int index) =>
      _reward('/api/v1/chests/$index/open');

  Future<ApiResult<ChestReward>> double(int index) =>
      _reward('/api/v1/chests/$index/double');

  Future<ApiResult<ChestReward>> _reward(String path) async {
    final response = await _client.post(path, {});
    return switch (response) {
      ApiOk(:final value) => ApiOk(ChestReward.fromJson(value)),
      ApiFailure(:final kind, :final detail, :final statusCode) => ApiFailure(
        kind,
        detail: detail,
        statusCode: statusCode,
      ),
    };
  }
}
