/// What came back, including the ways nothing did.
///
/// NOTHING IN THIS LAYER THROWS. A puzzle game that is playable on a plane
/// cannot have a network stack whose failure mode is an exception reaching the
/// UI, so every call returns one of these and every caller has to say what it
/// does when the answer is "no".
///
/// The failure KINDS exist because the right response differs. A timeout is
/// worth retrying later and worth saying nothing about; a rejected token means
/// re-authenticate and try once more; a refusal means the request was wrong
/// and repeating it will fail again forever.
library;

import 'package:flutter/foundation.dart';

enum ApiFailureKind {
  /// No backend is configured in this build. Not an error — see api_config.
  notConfigured,

  /// Could not reach the server: no network, DNS, TLS, connection refused.
  offline,

  /// The server took too long.
  timeout,

  /// 401. The session is gone or was never valid; re-authenticate.
  unauthorized,

  /// 4xx other than 401. The request itself was wrong.
  refused,

  /// 5xx, or a body we could not parse. Ours to fix, not the caller's.
  server,
}

@immutable
sealed class ApiResult<T> {
  const ApiResult();

  /// The value, or null on any failure. For callers that genuinely do not care
  /// why — most of the UI.
  T? get valueOrNull => switch (this) {
    ApiOk<T>(:final value) => value,
    ApiFailure<T>() => null,
  };

  bool get isOk => this is ApiOk<T>;
}

@immutable
final class ApiOk<T> extends ApiResult<T> {
  final T value;

  const ApiOk(this.value);
}

@immutable
final class ApiFailure<T> extends ApiResult<T> {
  final ApiFailureKind kind;

  /// The server's own message where there was one. Never shown raw to a
  /// player — it is written for us, not for them.
  final String? detail;

  final int? statusCode;

  const ApiFailure(this.kind, {this.detail, this.statusCode});

  /// Re-labels a failure for a different value type, so a caller can pass one
  /// up without inventing a value it does not have.
  ApiFailure<R> cast<R>() =>
      ApiFailure<R>(kind, detail: detail, statusCode: statusCode);

  /// True when trying again later is worth doing.
  ///
  /// A refusal is not: the request was malformed or the data was rejected, and
  /// the identical request will be rejected identically. Retrying it forever
  /// is how a client ends up hammering an endpoint that will never say yes.
  bool get isTransient =>
      kind == ApiFailureKind.offline ||
      kind == ApiFailureKind.timeout ||
      kind == ApiFailureKind.server;

  @override
  String toString() => 'ApiFailure($kind${detail == null ? '' : ': $detail'})';
}
