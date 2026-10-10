/// Ball skins and tube themes on the server: what this account owns, and what
/// it wears. Ownership is the server's call (chests, streaks, the Skin pack);
/// this only carries it.
library;

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'api_result.dart';

@immutable
class CosmeticItem {
  final String id;
  final String name;

  /// True for a ball skin, false for a tube theme.
  final bool isBallSkin;
  final bool owned;

  /// free, chest, streak or pack.
  final String source;

  /// The chest number or streak length it needs, or 0.
  final int value;

  const CosmeticItem({
    required this.id,
    required this.name,
    required this.isBallSkin,
    required this.owned,
    required this.source,
    required this.value,
  });

  /// How a locked one is unlocked, in a few words.
  String get unlockHint => switch (source) {
    'chest' => 'Star chest $value',
    'streak' => '$value-day streak',
    'pack' => 'Skin pack',
    _ => 'Free',
  };
}

@immutable
class CosmeticsInfo {
  final List<CosmeticItem> items;
  final String ballSkin;
  final String tubeTheme;
  final bool skinPackOwned;

  const CosmeticsInfo({
    required this.items,
    required this.ballSkin,
    required this.tubeTheme,
    required this.skinPackOwned,
  });

  static CosmeticsInfo fromJson(Map<String, Object?> body) => CosmeticsInfo(
    items: [
      for (final row in body['items'] as List? ?? const [])
        if (row is Map)
          CosmeticItem(
            id: row['id'] as String? ?? '',
            name: row['name'] as String? ?? '',
            isBallSkin: row['kind'] == 'ball_skin',
            owned: row['owned'] == true,
            source: row['source'] as String? ?? 'free',
            value: (row['value'] as num?)?.toInt() ?? 0,
          ),
    ],
    ballSkin: body['equipped_ball_skin'] as String? ?? 'classic',
    tubeTheme: body['equipped_tube_theme'] as String? ?? 'toy',
    skinPackOwned: body['skin_pack_owned'] == true,
  );
}

class CosmeticsApi {
  final ApiClient _client;

  const CosmeticsApi(this._client);

  Future<ApiResult<CosmeticsInfo>> list() async =>
      _parse(await _client.get('/api/v1/cosmetics'));

  Future<ApiResult<CosmeticsInfo>> equip({
    String? ballSkin,
    String? tubeTheme,
  }) async => _parse(
    await _client.put('/api/v1/cosmetics/equipped', {
      'ball_skin': ?ballSkin,
      'tube_theme': ?tubeTheme,
    }),
  );

  static ApiResult<CosmeticsInfo> _parse(
    ApiResult<Map<String, Object?>> response,
  ) => switch (response) {
    ApiOk(:final value) => ApiOk(CosmeticsInfo.fromJson(value)),
    ApiFailure(:final kind, :final detail, :final statusCode) => ApiFailure(
      kind,
      detail: detail,
      statusCode: statusCode,
    ),
  };
}
