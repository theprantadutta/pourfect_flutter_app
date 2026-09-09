/// The one place an HTTP request is made.
///
/// Deliberately small. It knows about JSON, bearer tokens, timeouts and how to
/// turn any failure into an [ApiResult] — and nothing about progress, dailies
/// or leaderboards, which live in their own services above it.
///
/// The bearer token is fetched through a callback rather than held here, so
/// this has no opinion about how a session is obtained or refreshed. That
/// keeps the retry-after-401 rule in one place (the session), instead of being
/// half here and half there.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_result.dart';
import 'app_env.dart';

/// Supplies the bearer token for a request, refreshing if needed.
///
/// Returns null when there is no session and one could not be obtained — the
/// client then fails the call rather than sending an unauthenticated request
/// that the server would reject anyway.
typedef TokenProvider = Future<String?> Function({bool forceRefresh});

class ApiClient {
  final http.Client _http;
  final String _baseUrl;
  final TokenProvider? _token;

  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    TokenProvider? tokenProvider,
  }) : _http = httpClient ?? http.Client(),
       _baseUrl = _trimTrailingSlash(baseUrl ?? AppEnv.apiBaseUrl),
       _token = tokenProvider;

  bool get isConfigured => _baseUrl.isNotEmpty;

  static String _trimTrailingSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  /// A request that carries no session — only `auth/device` does.
  Future<ApiResult<Map<String, Object?>>> postAnonymous(
    String path,
    Map<String, Object?> body,
  ) => _send('POST', path, body: body, authenticated: false);

  Future<ApiResult<Map<String, Object?>>> get(
    String path, {
    Map<String, String>? query,
  }) => _send('GET', path, query: query);

  Future<ApiResult<Map<String, Object?>>> post(
    String path,
    Map<String, Object?> body,
  ) => _send('POST', path, body: body);

  Future<ApiResult<Map<String, Object?>>> put(
    String path,
    Map<String, Object?> body,
  ) => _send('PUT', path, body: body);

  Future<ApiResult<Map<String, Object?>>> delete(String path) =>
      _send('DELETE', path);

  Future<ApiResult<Map<String, Object?>>> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    Map<String, String>? query,
    bool authenticated = true,
    bool isRetry = false,
  }) async {
    if (!isConfigured) {
      return const ApiFailure(ApiFailureKind.notConfigured);
    }

    String? token;
    if (authenticated) {
      token = await _token?.call(forceRefresh: isRetry);
      if (token == null) {
        return const ApiFailure(
          ApiFailureKind.unauthorized,
          detail: 'no session',
        );
      }
    }

    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{
      'accept': 'application/json',
      if (body != null) 'content-type': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
    };

    http.Response response;
    try {
      final request = switch (method) {
        'GET' => _http.get(uri, headers: headers),
        'DELETE' => _http.delete(uri, headers: headers),
        'PUT' => _http.put(uri, headers: headers, body: jsonEncode(body)),
        _ => _http.post(uri, headers: headers, body: jsonEncode(body)),
      };
      response = await request.timeout(kApiTimeout);
    } on TimeoutException {
      return const ApiFailure(ApiFailureKind.timeout);
    } catch (error) {
      // Socket errors, DNS, TLS, a proxy hanging up. All the same to a caller:
      // the server was not reached and trying later is the only option.
      debugPrint('[api] $method $path failed: $error');
      return ApiFailure(ApiFailureKind.offline, detail: '$error');
    }

    // ONE retry, and only for a rejected session.
    //
    // A 401 has exactly one cause worth handling automatically: the token
    // expired or was invalidated while the app was closed. Re-exchanging and
    // sending again turns that into something the player never sees. Retrying
    // anything else — or retrying twice — is how a client with a genuinely
    // dead credential hammers an endpoint that will never accept it.
    if (response.statusCode == 401 && authenticated && !isRetry) {
      return _send(
        method,
        path,
        body: body,
        query: query,
        authenticated: authenticated,
        isRetry: true,
      );
    }

    return _decode(response);
  }

  ApiResult<Map<String, Object?>> _decode(http.Response response) {
    final status = response.statusCode;

    if (status >= 200 && status < 300) {
      // 204, or a 200 with an empty body from a command that returns nothing.
      if (response.body.isEmpty) return const ApiOk({});
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, Object?>) return ApiOk(decoded);
        // A bare array or scalar. Wrapped so callers always see an object,
        // which is the shape every endpoint here is supposed to return.
        return ApiOk({'value': decoded});
      } catch (error) {
        return ApiFailure(
          ApiFailureKind.server,
          detail: 'unreadable body: $error',
          statusCode: status,
        );
      }
    }

    final detail = _errorMessage(response.body);

    return ApiFailure(
      switch (status) {
        401 => ApiFailureKind.unauthorized,
        >= 500 => ApiFailureKind.server,
        _ => ApiFailureKind.refused,
      },
      detail: detail,
      statusCode: status,
    );
  }

  /// Pulls the server's `{ "error": "..." }` out, if that is what it sent.
  static String? _errorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // A proxy's HTML error page, most likely. The status code is the useful
      // part; the body is noise.
    }
    return body.length > 200 ? body.substring(0, 200) : body;
  }

  void close() => _http.close();
}
