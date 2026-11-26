import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/features/auth/data/auth_api_client.dart';
import 'package:toggle_me/features/auth/data/models/auth_error_code.dart';
import 'package:toggle_me/features/auth/data/models/signup_request.dart';
import 'package:toggle_me/features/auth/data/signup_service.dart';

/// 실제 서버 대신 정해진 응답을 돌려주고, 보낸 요청을 기록하는 가짜 통신 장치
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.statusCode, this.body);

  final int statusCode;
  final String body;

  String? path;
  Map<String, dynamic>? sentBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    final data = options.data;
    sentBody = data is Map<String, dynamic>
        ? data
        : jsonDecode(data as String) as Map<String, dynamic>;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(ApiSignupService, _RecordingAdapter) _service(int status, [Object? body]) {
  final adapter = _RecordingAdapter(
    status,
    body == null ? '' : jsonEncode(body),
  );
  final dio = Dio(BaseOptions(baseUrl: 'https://test.example'))
    ..httpClientAdapter = adapter;
  return (ApiSignupService(client: AuthApiClient(dio: dio)), adapter);
}

final _request = SignupRequest(
  profile: SignupProfile(
    nickname: '토글러',
    gender: Gender.female,
    birthDate: DateTime(2000),
  ),
  account: const SignupAccount(
    loginId: 'toggle01',
    password: 'abcd123!',
    email: 'toggle01@example.com',
    emailVerificationToken: 'token-abc',
  ),
);
void main() {
  test('인증 코드 발송: 204(본문 없음)이면 성공, 이메일을 보낸다', () async {
    final (service, adapter) = _service(204);

    await service.requestEmailCode('toggle01@example.com');

    expect(adapter.path, '/api/v1/auth/email-verifications');
    expect(adapter.sentBody, {'email': 'toggle01@example.com'});
  });

  test('인증 코드 발송: 429면 서버 code와 문장을 그대로 던진다', () async {
    final (service, _) = _service(429, {
      'code': AuthErrorCode.emailVerificationTooManyRequests,
      'message': '잠시 후 다시 요청해 주세요.',
    });

    expect(
      service.requestEmailCode('toggle01@example.com'),
      throwsA(
        isA<AuthException>()
            .having(
              (e) => e.code,
              'code',
              AuthErrorCode.emailVerificationTooManyRequests,
            )
            .having((e) => e.message, 'message', '잠시 후 다시 요청해 주세요.'),
      ),
    );
  });

  test('인증 코드 확인: 코드는 문자열로 보내고 verificationToken을 돌려준다', () async {
    final (service, adapter) = _service(200, {'verificationToken': 'tok-1'});

    final token = await service.verifyEmailCode(
      email: 'toggle01@example.com',
      code: '012345',
    );

    expect(token, 'tok-1');
    expect(adapter.path, '/api/v1/auth/email-verifications/confirm');
    expect(adapter.sentBody, {
      'email': 'toggle01@example.com',
      'code': '012345', // 앞자리 0 유지
    });
  });

  test('인증 코드 확인: 400 EMAIL_VERIFICATION_CODE_INVALID', () async {
    final (service, _) = _service(400, {
      'code': AuthErrorCode.emailVerificationCodeInvalid,
      'message': '인증 코드가 올바르지 않습니다.',
    });

    expect(
      service.verifyEmailCode(email: 'a@b.com', code: '111111'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.code,
          'code',
          AuthErrorCode.emailVerificationCodeInvalid,
        ),
      ),
    );
  });

  test('회원가입: 명세대로 loginId·email·토큰·password·nickname을 보낸다', () async {
    final (service, adapter) = _service(201, {
      'accessToken': 'a',
      'refreshToken': 'r',
      'tokenType': 'Bearer',
      'expiresIn': 1800,
      'onboardingRequired': true,
      'onboardingStep': 'PROFILE',
    });

    await service.signup(_request);

    expect(adapter.path, '/api/v1/auth/signup');
    expect(adapter.sentBody, {
      'loginId': 'toggle01',
      'email': 'toggle01@example.com',
      'emailVerificationToken': 'token-abc',
      'password': 'abcd123!',
      'nickname': '토글러',
    });
  });

  test('회원가입: 409 LOGIN_ID_ALREADY_EXISTS', () async {
    final (service, _) = _service(409, {
      'code': AuthErrorCode.loginIdAlreadyExists,
      'message': '이미 사용 중인 아이디입니다.',
    });

    expect(
      service.signup(_request),
      throwsA(
        isA<AuthException>().having(
          (e) => e.code,
          'code',
          AuthErrorCode.loginIdAlreadyExists,
        ),
      ),
    );
  });

  test('아이디 중복확인 API가 없어서 형식 확인만 한다', () async {
    final (service, adapter) = _service(200, {});

    expect(await service.checkLoginId('toggle01'), LoginIdCheck.formatOnly);
    expect(adapter.path, isNull); // 서버에 요청하지 않음
  });
}
