import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

/// 카카오 SDK로 로그인해서 '카카오 Access Token'을 받아오는 담당.
/// (우리 서비스 토큰이 아니에요. 이 토큰을 서버에 보내면 서버가 우리 토큰을 줘요.)
class KakaoAuthClient {
  /// 카카오 키는 코드에 직접 쓰지 않고, 실행할 때
  /// --dart-define-from-file=dart_defines.json 으로 넣어요. (git에 안 올라감)
  /// 앱(Android·iOS)은 네이티브 앱 키, 웹은 JavaScript 키를 써요.
  static const _nativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
  static const _javaScriptAppKey = String.fromEnvironment(
    'KAKAO_JAVASCRIPT_APP_KEY',
  );

  static bool _initialized = false;

  /// 지금 실행 중인 곳(웹/앱)에 필요한 키가 설정돼 있는지
  /// (키가 없는 팀원 환경에서 앱이 꺼지지 않게 확인용)
  bool get hasAppKey =>
      kIsWeb ? _javaScriptAppKey.isNotEmpty : _nativeAppKey.isNotEmpty;

  /// 카카오 로그인 후 카카오 Access Token을 돌려줘요.
  /// 사용자가 취소하면 null을 돌려줘요. (설계서 상태 5: 오류 메시지 없음)
  Future<String?> login() async {
    await _ensureInitialized();

    try {
      final OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        token = await _loginWithKakaoTalkOrAccount();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }
      return token.accessToken;
    } catch (error) {
      if (_isCanceled(error)) return null;
      rethrow;
    }
  }

  /// 카카오톡으로 로그인. 취소가 아닌 이유로 실패하면 카카오계정 로그인으로 다시 시도해요.
  /// (카카오톡은 있지만 카카오계정이 연결되지 않은 경우 등, 카카오 공식 권장 방식)
  Future<OAuthToken> _loginWithKakaoTalkOrAccount() async {
    try {
      return await UserApi.instance.loginWithKakaoTalk();
    } catch (error) {
      if (_isCanceled(error)) rethrow;
      return UserApi.instance.loginWithKakaoAccount();
    }
  }

  /// 사용자가 로그인을 취소했는지 확인해요.
  bool _isCanceled(Object error) {
    // 카카오톡·브라우저 로그인 창을 닫았을 때
    if (error is PlatformException && error.code == 'CANCELED') return true;
    // 동의 화면에서 [취소]를 눌렀을 때
    if (error is KakaoAuthException &&
        error.error == AuthErrorCause.accessDenied) {
      return true;
    }
    if (error is KakaoClientException &&
        error.reason == ClientErrorCause.cancelled) {
      return true;
    }
    return false;
  }

  /// SDK 초기화는 처음 로그인할 때 한 번만 해요.
  /// 여기서 하면 팀 공통 파일인 main.dart를 고치지 않아도 돼요.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (!hasAppKey) {
      throw const KakaoAppKeyMissingException();
    }
    // 두 키를 모두 넘기면 SDK가 웹/앱에 맞는 키를 골라 써요.
    // (공유하기도 같은 SDK를 초기화해서, 두 곳 모두 같은 키를 넘겨야 해요.)
    await KakaoSdk.init(
      nativeAppKey: _nativeAppKey,
      javaScriptAppKey: _javaScriptAppKey,
    );
    _initialized = true;
  }
}

/// 카카오 앱 키(앱: 네이티브, 웹: JavaScript)가 설정되지 않았을 때 던지는 예외
class KakaoAppKeyMissingException implements Exception {
  const KakaoAppKeyMissingException();

  @override
  String toString() => '카카오 키가 설정되지 않았어요. dart_defines.json을 확인해 주세요.';
}
