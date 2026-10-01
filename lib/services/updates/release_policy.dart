/// Which builds the game still supports, set from the admin dashboard.
///
/// The server decides nothing about the caller: it publishes the latest and
/// minimum supported versions per platform, and the app compares its own.
/// On Android, Play's in-app update decides what is AVAILABLE; this decides
/// only whether the player may say Not now. Below the minimum, they cannot.
library;

import '../api/api_client.dart';
import '../api/api_result.dart';
import '../diagnostics/diagnostics.dart';

class ReleasePolicy {
  final String latestVersion;
  final String minimumSupportedVersion;
  final String storeUrl;
  final bool enabled;

  const ReleasePolicy({
    required this.latestVersion,
    required this.minimumSupportedVersion,
    required this.storeUrl,
    required this.enabled,
  });

  /// True when [currentVersion] is below the minimum and the policy is on.
  ///
  /// Anything unparseable is NOT below: an app must never lock a player out
  /// on a version string it could not read.
  bool requiresUpdate(String currentVersion) {
    if (!enabled) return false;
    final current = parseVersion(currentVersion);
    final minimum = parseVersion(minimumSupportedVersion);
    if (current == null || minimum == null) return false;
    return compareVersions(current, minimum) < 0;
  }
}

/// "2.1.1" → [2, 1, 1]. Same rule as the backend's AppVersion: one to four
/// dot-separated numbers. Null for anything else, including "2.1.1+11" build
/// suffixes, which are stripped by the caller.
List<int>? parseVersion(String text) {
  final trimmed = text.trim();
  if (!RegExp(r'^\d{1,6}(\.\d{1,6}){0,3}$').hasMatch(trimmed)) return null;
  return [for (final part in trimmed.split('.')) int.parse(part)];
}

/// Segment by segment, a missing segment counting as 0: 2.10 is above 2.9.
int compareVersions(List<int> a, List<int> b) {
  for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

/// Reads the policy. Null on any failure: no answer means no lock-out.
Future<ReleasePolicy?> fetchReleasePolicy(
  ApiClient client,
  String platform,
) async {
  if (!client.isConfigured) return null;
  final result = await client.getAnonymous('/api/v1/app-release/$platform');
  switch (result) {
    case ApiOk(:final value):
      final latest = value['latest_version'];
      final minimum = value['minimum_supported_version'];
      if (latest is! String || minimum is! String) return null;
      return ReleasePolicy(
        latestVersion: latest,
        minimumSupportedVersion: minimum,
        storeUrl: value['store_url'] as String? ?? '',
        enabled: value['enabled'] as bool? ?? false,
      );
    case ApiFailure(:final kind):
      logLine('update', 'no release policy: $kind');
      return null;
  }
}
