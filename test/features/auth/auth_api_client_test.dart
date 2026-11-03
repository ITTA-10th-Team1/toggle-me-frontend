import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/features/auth/data/auth_api_client.dart';
import 'package:toggle_me/features/auth/data/models/auth_error_code.dart';

/// 실제 서버 대신 정해진 상태 코드와 본문을 돌려주는 가짜 통신 장치
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode, this.body, {this.contentType});

  final int statusCode;
  final String body;
  final String? contentType;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [contentType ?? Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

AuthApiClient _client(int status, Object body, {String? contentType}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.example'))
    ..httpClientAdapter = _FakeAdapter(
      status,
      body is String ? body : jsonEncode(body),
      contentType: contentType,
    );
  return AuthApiClient(dio: dio);
}

Matcher _authError(String code, String message) => throwsA(
  isA<AuthException>()
      .having((e) => e.code, 'code', code)
      .having((e) => e.message, 'message', message),
);

void main() {
  test('200이면 응답 JSON을 돌려준다', () async {
    final client = _client(200, {'accessToken': 'a'});

    expect(await client.post('/x', {}), {'accessToken': 'a'});
  });

  test('401 CREDENTIALS_INVALID → 설계서 문구', () async {
    final client = _client(401, {
      'code': 'CREDENTIALS_INVALID',
      'message': '서버 문구',
      'errors': [],
    });

    await expectLater(
      client.post('/x', {}),
      _authError('CREDENTIALS_INVALID', '아이디 또는 비밀번호가 올바르지 않습니다.'),
    );
  });

  test('502 KAKAO_API_ERROR → 서버 message 그대로', () async {
    final client = _client(502, {
      'code': 'KAKAO_API_ERROR',
      'message': '카카오 서버와 통신하지 못했습니다.',
      'errors': [],
    });

    await expectLater(
      client.post('/x', {}),
      _authError('KAKAO_API_ERROR', '카카오 서버와 통신하지 못했습니다.'),
    );
  });

  test('그 밖의 오류 → 서버 message 그대로', () async {
    final client = _client(400, {
      'code': 'INVALID_INPUT_VALUE',
      'message': '요청 값이 올바르지 않습니다.',
      'errors': [
        {'field': 'password', 'reason': '비밀번호는 필수입니다.'},
      ],
    });

    await expectLater(
      client.post('/x', {}),
      _authError('INVALID_INPUT_VALUE', '요청 값이 올바르지 않습니다.'),
    );
  });

  test('JSON이 아닌 오류 응답 → 기본 문구', () async {
    final client = _client(
      500,
      '<html>Bad Gateway</html>',
      contentType: 'text/html',
    );

    await expectLater(
      client.post('/x', {}),
      _authError(AuthErrorCode.unknown, '로그인 중 문제가 생겼어요.'),
    );
  });

  test('서버 주소가 없으면 요청하지 않고 안내한다', () async {
    final client = AuthApiClient(dio: Dio());

    await expectLater(
      client.post('/x', {}),
      throwsA(
        isA<AuthException>().having(
          (e) => e.code,
          'code',
          AuthErrorCode.apiBaseUrlMissing,
        ),
      ),
    );
  });

  group('네트워크 오류 → "네트워크 연결을 확인해 주세요."', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.transformTimeout,
      DioExceptionType.connectionError,
    ]) {
      test(type.name, () {
        final e = authExceptionFromDio(
          DioException(requestOptions: RequestOptions(), type: type),
        );

        expect(e.code, AuthErrorCode.networkError);
        expect(e.message, '네트워크 연결을 확인해 주세요.');
      });
    }
  });
}
