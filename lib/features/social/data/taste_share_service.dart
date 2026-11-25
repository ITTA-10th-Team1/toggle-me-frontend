import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';

/// 공유할 내용: 'OO님의 취향' + 해시태그 (+ 링크)
class TasteShareContent {
  const TasteShareContent({required this.title, required this.tags});

  final String title;
  final List<String> tags;

  /// 공유 링크. 실행할 때 --dart-define으로 넣어요. 없으면 빈 값.
  // TODO(share): 링크를 누르면 어디로 갈지(웹 페이지, 앱 화면) 팀·백엔드와 정하기.
  //   카카오톡 메시지에 링크를 넣으려면 카카오 개발자 콘솔에 그 사이트 도메인을 등록해야 해요.
  static const link = String.fromEnvironment('SHARE_LINK_URL');

  /// 해시태그 한 줄. 예: '#데님 #빵'
  String get hashtagLine => tags.map((tag) => '#$tag').join(' ');

  /// 링크 복사·카카오톡 메시지에 쓰는 글
  String get text {
    final lines = [title, hashtagLine, if (link.isNotEmpty) link];
    return lines.join('\n');
  }
}

/// 공유하기 담당: 카카오톡 공유, 링크 복사
/// 화면은 이 틀만 알아서, 테스트에서는 가짜로 바꿔 끼울 수 있어요.
abstract class TasteShareService {
  Future<void> shareToKakaoTalk(TasteShareContent content);

  Future<void> copyLink(TasteShareContent content);
}

/// 실제 공유 서비스 (카카오 SDK + 클립보드)
class KakaoTasteShareService implements TasteShareService {
  /// 카카오 키는 로그인과 같은 값을 써요. (dart_defines.json, git 제외)
  /// 앱(Android·iOS)은 네이티브 앱 키, 웹은 JavaScript 키를 써요.
  static const _nativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
  static const _javaScriptAppKey = String.fromEnvironment(
    'KAKAO_JAVASCRIPT_APP_KEY',
  );

  /// 지금 실행 중인 곳(웹/앱)에 필요한 키가 설정돼 있는지
  static bool get _hasAppKey =>
      kIsWeb ? _javaScriptAppKey.isNotEmpty : _nativeAppKey.isNotEmpty;

  static bool _initialized = false;

  @override
  Future<void> shareToKakaoTalk(TasteShareContent content) async {
    await _ensureInitialized();

    final template = TextTemplate(
      text: content.text,
      link: Link(webUrl: _linkUri, mobileWebUrl: _linkUri),
    );

    // 카카오톡이 있으면 카카오톡으로, 없으면 브라우저의 카카오 공유 페이지로 열어요.
    if (await ShareClient.instance.isKakaoTalkSharingAvailable()) {
      await ShareClient.instance.shareDefault(template: template);
    } else {
      final url = await WebSharerClient.instance.makeDefaultUrl(
        template: template,
      );
      await launchBrowser(url);
    }
  }

  @override
  Future<void> copyLink(TasteShareContent content) {
    return Clipboard.setData(ClipboardData(text: content.text));
  }

  Uri? get _linkUri =>
      TasteShareContent.link.isEmpty ? null : Uri.parse(TasteShareContent.link);

  /// SDK 초기화는 처음 공유할 때 한 번만 해요. (main.dart를 고치지 않으려고)
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (!_hasAppKey) throw const KakaoShareKeyMissingException();
    // 두 키를 모두 넘기면 SDK가 웹/앱에 맞는 키를 골라 써요.
    // (로그인도 같은 SDK를 초기화해서, 두 곳 모두 같은 키를 넘겨야 해요.)
    await KakaoSdk.init(
      nativeAppKey: _nativeAppKey,
      javaScriptAppKey: _javaScriptAppKey,
    );
    _initialized = true;
  }
}

/// 카카오 앱 키(앱: 네이티브, 웹: JavaScript)가 설정되지 않았을 때 던지는 예외
class KakaoShareKeyMissingException implements Exception {
  const KakaoShareKeyMissingException();

  @override
  String toString() => '카카오 키가 설정되지 않았어요. dart_defines.json을 확인해 주세요.';
}
