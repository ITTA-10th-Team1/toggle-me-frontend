import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'models/auth_error_code.dart';

/// 인증 API에 요청을 보내는 담당.
///
/// TODO(network): 팀 공통 API 구조(lib/core/network)가 정해지면 그쪽으로 옮기기.
///   토큰 자동 갱신, 401 재시도도 그때 같이 맞춰요.
class AuthApiClient {
  AuthApiClient({Dio? dio}) : _dio = dio ?? _createDio();

  /// 서버 주소는 코드에 직접 쓰지 않고, 실행할 때
  /// --dart-define-from-file=dart_defines.json 으로 넣어요.
  static const _baseUrl = String.fromEnvironment('API_BASE_URL');

  static const _timeout = Duration(seconds: 10);

  final Dio _dio;

  static Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: _timeout, // 서버에 연결하기까지
        receiveTimeout: _timeout, // 응답을 다 받기까지
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );
  }

  /// JSON 본문으로 POST 요청을 보내고, 응답 JSON을 돌려줘요.
  /// 실패하면 [AuthException]을 던져요.
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    if (_dio.options.baseUrl.isEmpty) {
      throw const AuthException(
        AuthErrorCode.apiBaseUrlMissing,
        '서버 주소가 설정되지 않았어요. dart_defines.json을 확인해 주세요.',
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      final data = response.data;
      if (data == null) {
        throw const AuthException(AuthErrorCode.unknown, _unknownMessage);
      }
      return data;
    } on DioException catch (e) {
      throw authExceptionFromDio(e);
    }
  }
}

const _networkMessage = '네트워크 연결을 확인해 주세요.';
const _credentialsInvalidMessage = '아이디 또는 비밀번호가 올바르지 않습니다.';
const _unknownMessage = '로그인 중 문제가 생겼어요.';

/// dio 오류를 화면에 보여줄 [AuthException]으로 바꿔요.
@visibleForTesting
AuthException authExceptionFromDio(DioException e) {
  switch (e.type) {
    // 서버 응답 없음·시간 초과·인터넷 끊김
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const AuthException(AuthErrorCode.networkError, _networkMessage);

    // 서버가 오류 응답을 보냄: { code, message, errors }
    case DioExceptionType.badResponse:
      final data = e.response?.data;
      if (data is Map && data['code'] is String) {
        final code = data['code'] as String;
        if (code == AuthErrorCode.credentialsInvalid) {
          return AuthException(code, _credentialsInvalidMessage);
        }
        final message = data['message'];
        return AuthException(
          code,
          message is String && message.isNotEmpty ? message : _unknownMessage,
        );
      }
      return const AuthException(AuthErrorCode.unknown, _unknownMessage);

    case DioExceptionType.unknown:
      // 인터넷이 끊기면 여기로 오는 경우도 있어요.
      if (e.error is SocketException) {
        return const AuthException(AuthErrorCode.networkError, _networkMessage);
      }
      return const AuthException(AuthErrorCode.unknown, _unknownMessage);

    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
      return const AuthException(AuthErrorCode.unknown, _unknownMessage);
  }
}
