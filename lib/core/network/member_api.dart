import 'package:dio/dio.dart';

import '../../features/auth/data/token_storage.dart';
import 'api_client.dart';

/// Uses the login team's token keys and base URL. One instance per app session.
class MemberApi {
  MemberApi({Dio? dio, TokenStorage? tokens})
    : dio = dio ?? ApiClient().dio,
      tokens = tokens ?? TokenStorage();

  final Dio dio;
  final TokenStorage tokens;
  Future<_TokenRotation>? _refreshing;
  _TokenRotation? _lastRotation;
  _SessionIdentity? _sessionIdentity;

  /// A capability for a multi-request operation. It follows only token rotations
  /// validated by this client, and never adopts another login's stored tokens.
  Future<MemberApiSession> captureSession({bool Function()? isActive}) async {
    final pending = _refreshing;
    if (pending != null) await pending;
    final access = await accessToken();
    final refresh = await tokens.getRefreshToken();
    if (await tokens.getAccessToken() != access ||
        await tokens.getRefreshToken() != refresh) {
      throw _sessionChanged;
    }
    var identity = _sessionIdentity;
    if (identity == null ||
        identity.access != access ||
        identity.refresh != refresh) {
      identity = _SessionIdentity(access, refresh);
      _sessionIdentity = identity;
    }
    final session = MemberApiSession._(this, identity, isActive ?? () => true);
    await session.ensureActive();
    return session;
  }

  Future<bool> get hasSession async =>
      (await tokens.getAccessToken())?.isNotEmpty == true ||
      (await tokens.getRefreshToken())?.isNotEmpty == true;

  Future<String> accessToken() async {
    final access = await tokens.getAccessToken();
    if (access == null || access.isEmpty) {
      return _validatedAccess(await _refresh());
    }
    return access;
  }

  /// Shared by room, feed, upload and detail requests. Rotate only once when
  /// several requests discover the same expired token concurrently.
  Future<String> refreshAccessToken(String rejected) async {
    final current = await tokens.getAccessToken();
    final _TokenRotation rotation;
    if (current == rejected) {
      rotation = await _refresh();
    } else {
      final previous = _lastRotation;
      if (previous == null || previous.access != current) {
        throw _sessionChanged;
      }
      rotation = previous;
    }
    if (rotation.previousAccess != rejected) {
      throw _sessionChanged;
    }
    // Return only this rotation's token, never the latest account's token.
    return _validatedAccess(rotation);
  }

  static const _sessionChanged = MemberApiException(
    'UNAUTHORIZED',
    '로그인 상태가 변경되었어요.',
  );

  Future<bool> _matchesTokens(String? access, String refresh) async =>
      await tokens.getAccessToken() == access &&
      await tokens.getRefreshToken() == refresh;

  Future<String> _validatedAccess(_TokenRotation rotation) async {
    if (!await _matchesTokens(rotation.access, rotation.refresh)) {
      throw _sessionChanged;
    }
    return rotation.access;
  }

  Future<dynamic> request(String method, String path, {Object? data}) async {
    if (dio.options.baseUrl.isEmpty) {
      throw const MemberApiException('CONFIGURATION', '서버 주소가 설정되지 않았어요.');
    }
    final access = await accessToken();
    try {
      return await _send(method, path, data, access);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 &&
          e.response?.data is Map &&
          e.response?.data['code'] == 'UNAUTHORIZED') {
        final next = await refreshAccessToken(access);
        try {
          return await _send(method, path, data, next);
        } on DioException catch (retry) {
          throw MemberApiException.fromDio(retry);
        }
      }
      throw MemberApiException.fromDio(e);
    }
  }

  Future<dynamic> _send(
    String method,
    String path,
    Object? data,
    String access,
  ) async => (await dio.request<dynamic>(
    path,
    data: path == '/api/v1/auth/logout'
        ? {'refreshToken': await tokens.getRefreshToken()}
        : data,
    options: Options(
      method: method,
      headers: {'Authorization': 'Bearer $access'},
    ),
  )).data;

  Future<_TokenRotation> _refresh() async {
    final pending = _refreshing;
    if (pending != null) return pending;
    final work = _rotateTokens();
    _refreshing = work;
    try {
      return await work;
    } finally {
      _refreshing = null;
    }
  }

  Future<_TokenRotation> _rotateTokens() async {
    final previousAccess = await tokens.getAccessToken();
    final refresh = await tokens.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw const MemberApiException('UNAUTHORIZED', '로그인이 필요해요.');
    }
    if (!await _matchesTokens(previousAccess, refresh)) throw _sessionChanged;
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/auth/token/refresh',
        data: {'refreshToken': refresh},
      );
      final body = response.data!;
      // Do not restore a session that was logged out/replaced while waiting.
      if (!await _matchesTokens(previousAccess, refresh)) throw _sessionChanged;
      final rotation = _TokenRotation(
        previousAccess: previousAccess,
        access: body['accessToken'] as String,
        refresh: body['refreshToken'] as String,
      );
      await tokens.saveTokens(
        accessToken: rotation.access,
        refreshToken: rotation.refresh,
      );
      await _validatedAccess(rotation);
      _lastRotation = rotation;
      final identity = _sessionIdentity;
      if (identity != null &&
          identity.access == previousAccess &&
          identity.refresh == refresh) {
        identity.access = rotation.access;
        identity.refresh = rotation.refresh;
      }
      return rotation;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 &&
          await _matchesTokens(previousAccess, refresh)) {
        await tokens.clearTokens();
      }
      throw MemberApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    final refresh = await tokens.getRefreshToken();
    try {
      if (refresh != null) {
        await request(
          'POST',
          '/api/v1/auth/logout',
          data: {'refreshToken': refresh},
        );
      }
    } finally {
      await tokens.clearTokens();
    }
  }
}

class _SessionIdentity {
  _SessionIdentity(this.access, this.refresh);
  String access;
  String? refresh;
}

/// Requests keep the captured session's Authorization header even if storage
/// changes after validation. A normal refresh updates the same identity object.
class MemberApiSession {
  MemberApiSession._(this._api, this._identity, this._isActive);
  final MemberApi _api;
  final _SessionIdentity _identity;
  final bool Function() _isActive;

  Future<String> _accessForRequest() async {
    while (true) {
      if (!_isActive()) throw MemberApi._sessionChanged;
      final access = _identity.access;
      final refresh = _identity.refresh;
      final currentAccess = await _api.tokens.getAccessToken();
      final currentRefresh = await _api.tokens.getRefreshToken();
      if (!_isActive()) throw MemberApi._sessionChanged;
      if (access != _identity.access || refresh != _identity.refresh) continue;
      if (currentAccess == access && currentRefresh == refresh) return access;
      // A concurrent, verified refresh may be between saving tokens and
      // advancing the identity. Wait for that rotation, never a different login.
      final pending = _api._refreshing;
      if (pending != null) {
        await pending;
        continue;
      }
      throw MemberApi._sessionChanged;
    }
  }

  Future<void> ensureActive() async {
    await _accessForRequest();
  }

  Future<dynamic> request(String method, String path, {Object? data}) async {
    if (_api.dio.options.baseUrl.isEmpty) {
      throw const MemberApiException('CONFIGURATION', '서버 주소가 설정되지 않았어요.');
    }
    final access = await _accessForRequest();
    try {
      final result = await _api._send(method, path, data, access);
      await ensureActive();
      return result;
    } on DioException catch (e) {
      await ensureActive();
      if (e.response?.statusCode == 401 &&
          e.response?.data is Map &&
          e.response?.data['code'] == 'UNAUTHORIZED') {
        final verified = await _accessForRequest();
        final next = verified == access
            ? await _api.refreshAccessToken(access)
            : verified;
        await ensureActive();
        try {
          final result = await _api._send(method, path, data, next);
          await ensureActive();
          return result;
        } on DioException catch (retry) {
          await ensureActive();
          throw MemberApiException.fromDio(retry);
        }
      }
      throw MemberApiException.fromDio(e);
    }
  }
}

class _TokenRotation {
  const _TokenRotation({
    required this.previousAccess,
    required this.access,
    required this.refresh,
  });
  final String? previousAccess;
  final String access;
  final String refresh;
}

class MemberApiException implements Exception {
  const MemberApiException(this.code, this.message, [this.errors = const []]);
  final String code;
  final String message;
  final List<dynamic> errors;
  factory MemberApiException.fromDio(DioException e) {
    final body = e.response?.data;
    if (body is Map) {
      return MemberApiException(
        body['code'] as String? ?? 'UNKNOWN',
        body['message'] as String? ?? '요청을 처리하지 못했어요.',
        body['errors'] is List ? body['errors'] as List : const [],
      );
    }
    return const MemberApiException('NETWORK', '연결을 확인하고 다시 시도해 주세요.');
  }
  @override
  String toString() => message;
}

final memberApi = MemberApi();
