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
  Future<void>? _refreshing;

  Future<bool> get hasSession async =>
      (await tokens.getAccessToken())?.isNotEmpty == true ||
      (await tokens.getRefreshToken())?.isNotEmpty == true;

  Future<dynamic> request(String method, String path, {Object? data}) async {
    if (dio.options.baseUrl.isEmpty) {
      throw const MemberApiException('CONFIGURATION', '서버 주소가 설정되지 않았어요.');
    }
    var access = await tokens.getAccessToken();
    if (access == null || access.isEmpty) {
      await _refresh();
      access = await tokens.getAccessToken();
    }
    try {
      return await _send(method, path, data, access!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 &&
          e.response?.data is Map &&
          e.response?.data['code'] == 'UNAUTHORIZED') {
        // Another request may already have rotated the token.
        if (await tokens.getAccessToken() == access) await _refresh();
        final next = await tokens.getAccessToken();
        if (next == null) {
          throw const MemberApiException('UNAUTHORIZED', '다시 로그인해 주세요.');
        }
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

  Future<void> _refresh() async {
    if (_refreshing != null) return _refreshing;
    final work = _rotateTokens();
    _refreshing = work;
    try {
      await work;
    } finally {
      _refreshing = null;
    }
  }

  Future<void> _rotateTokens() async {
    final refresh = await tokens.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw const MemberApiException('UNAUTHORIZED', '로그인이 필요해요.');
    }
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/auth/token/refresh',
        data: {'refreshToken': refresh},
      );
      final body = response.data!;
      // Do not restore a session that was logged out/replaced while waiting.
      if (await tokens.getRefreshToken() != refresh) {
        throw const MemberApiException('UNAUTHORIZED', '로그인 상태가 변경되었어요.');
      }
      await tokens.saveTokens(
        accessToken: body['accessToken'] as String,
        refreshToken: body['refreshToken'] as String,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 &&
          await tokens.getRefreshToken() == refresh) {
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
