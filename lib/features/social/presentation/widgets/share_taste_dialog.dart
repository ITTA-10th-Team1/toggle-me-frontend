import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/taste_share_service.dart';

/// 공유하기 팝업을 띄워요. (이슈 #38)
/// [tags]는 내가 등록한 취향 태그예요. '#' 없이 글자만 넘겨요. (예: ['데님', '빵'])
/// [nickname]이 없으면 'OO님의 취향' 대신 '나의 취향'으로 보여줘요.
Future<void> showShareTasteDialog(
  BuildContext context, {
  required List<String> tags,
  String? nickname,
  TasteShareService? service,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        ShareTasteDialog(tags: tags, nickname: nickname, service: service),
  );
}

/// 취향 공유 팝업: 위에 내 취향 카드, 아래에 [공유하기] [내 방으로] 버튼
class ShareTasteDialog extends StatefulWidget {
  const ShareTasteDialog({
    super.key,
    required this.tags,
    this.nickname,
    this.service,
  });

  final List<String> tags;
  final String? nickname;

  /// 안 넣으면 실제 공유 서비스(카카오 SDK + 클립보드)를 써요.
  final TasteShareService? service;

  /// 필요한 태그 수. 이보다 적으면 '태그가 부족해요' 안내를 보여주고,
  /// 많으면 앞에서부터 이만큼만 카드에 보여줘요.
  static const requiredTags = 5;

  /// 팝업 크기가 내용에 따라 바뀌지 않게 고정한 높이
  static const cardHeight = 240.0;
  static const messageHeight = 20.0;

  @override
  State<ShareTasteDialog> createState() => _ShareTasteDialogState();
}

class _ShareTasteDialogState extends State<ShareTasteDialog> {
  late final TasteShareService _service =
      widget.service ?? KakaoTasteShareService();

  /// 버튼 아래에 잠깐 보여주는 결과 문구 (예: '링크를 복사했어요.')
  String? _message;

  String get _title {
    final nickname = widget.nickname;
    if (nickname == null || nickname.isEmpty) return '나의 취향';
    return '$nickname님의 취향';
  }

  bool get _hasEnoughTags =>
      widget.tags.length >= ShareTasteDialog.requiredTags;

  TasteShareContent get _content =>
      TasteShareContent(title: _title, tags: widget.tags);

  // ───────── 공유하기 ─────────

  Future<void> _onSharePressed() async {
    final option = await showModalBottomSheet<_ShareOption>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ShareOptionSheet(),
    );
    if (option == null || !mounted) return; // 시트를 그냥 닫음

    switch (option) {
      case _ShareOption.kakaoTalk:
        await _shareToKakaoTalk();
      case _ShareOption.copyLink:
        await _copyLink();
    }
  }

  Future<void> _shareToKakaoTalk() async {
    try {
      await _service.shareToKakaoTalk(_content);
      _setMessage(null);
    } on KakaoShareKeyMissingException catch (e) {
      _setMessage(e.toString());
    } catch (_) {
      _setMessage('카카오톡으로 공유하지 못했어요. 다시 시도해 주세요.');
    }
  }

  Future<void> _copyLink() async {
    try {
      await _service.copyLink(_content);
      _setMessage('링크를 복사했어요.');
    } catch (_) {
      _setMessage('복사하지 못했어요. 다시 시도해 주세요.');
    }
  }

  void _setMessage(String? message) {
    if (mounted) setState(() => _message = message);
  }

  // ───────── 화면 ─────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPreview(),
          const SizedBox(height: 32),
          _buildButtons(),
          const SizedBox(height: 12),
          // 문구가 없어도 자리를 비워 둬서, 문구가 나타날 때 팝업 크기가 바뀌지 않아요.
          SizedBox(
            height: ShareTasteDialog.messageHeight,
            child: Text(
              _message ?? '',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                letterSpacing: -0.35,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 위쪽: 살구색 그라데이션 + 내 취향 카드 (가로 전체를 써서 크게)
  Widget _buildPreview() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_ShareColors.gradientTop, AppColors.white],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _ShareColors.previewBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: _TasteCard(
            title: _title,
            // 5개가 안 되면 null → 카드에 '태그가 부족해요' 안내
            tags: _hasEnoughTags
                ? widget.tags.take(ShareTasteDialog.requiredTags).toList()
                : null,
          ),
        ),
      ),
    );
  }

  /// 아래쪽: [공유하기] [내 방으로] 같은 줄, 같은 크기
  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _PillButton(
              label: '공유하기',
              icon: Icons.share_outlined,
              backgroundColor: _ShareColors.accent,
              // 태그가 5개가 안 되면 꺼져요.
              onPressed: _hasEnoughTags ? _onSharePressed : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PillButton(
              label: '내 방으로',
              backgroundColor: AppColors.authBlack,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 흰 카드: 'OO님의 취향' + 태그들 (높이 고정)
class _TasteCard extends StatelessWidget {
  const _TasteCard({required this.title, required this.tags});

  final String title;

  /// null이면 태그가 부족하다는 안내를 보여줘요.
  final List<String>? tags;

  @override
  Widget build(BuildContext context) {
    final tags = this.tags;
    return Container(
      width: double.infinity,
      height: ShareTasteDialog.cardHeight,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.45,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tags == null
                ? const _NotEnoughTags()
                // 태그가 아주 길어 칸을 넘치면 카드 안에서 스크롤돼요.
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: [for (final tag in tags) _TagChip(text: tag)],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 태그가 5개보다 적을 때 카드 안에 보여주는 안내
class _NotEnoughTags extends StatelessWidget {
  const _NotEnoughTags();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '아직 태그가 부족해서 볼 수 없어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '태그가 ${ShareTasteDialog.requiredTags}개 모이면 공유할 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              letterSpacing: -0.35,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 태그 한 개: 연한 살구색 배경 + 주황 테두리
class _TagChip extends StatelessWidget {
  const _TagChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: _ShareColors.chipBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ShareColors.accent),
      ),
      child: Text(
        '#$text',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 17,
          letterSpacing: -0.425,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// 양옆이 둥근 큰 버튼 (높이 56)
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.disabled,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ShareOption { kakaoTalk, copyLink }

/// [공유하기]를 누르면 아래에서 올라오는 선택 창: 카카오톡으로 공유하기 / 링크 복사
class _ShareOptionSheet extends StatelessWidget {
  const _ShareOptionSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _optionTile(
              context,
              option: _ShareOption.kakaoTalk,
              label: '카카오톡으로 공유하기',
              icon: Icons.chat_bubble,
              iconColor: AppColors.textPrimary,
              iconBackground: AppColors.kakao,
            ),
            _optionTile(
              context,
              option: _ShareOption.copyLink,
              label: '링크 복사',
              icon: Icons.link,
              iconColor: _ShareColors.icon,
              iconBackground: _ShareColors.linkIconBackground,
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(
    BuildContext context, {
    required _ShareOption option,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return ListTile(
      onTap: () => Navigator.of(context).pop(option),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: iconBackground,
        child: Icon(icon, size: 22, color: iconColor),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 17,
          letterSpacing: -0.425,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// 공유하기 팝업에서만 쓰는 색 (피그마 캡처에서 추정)
// TODO(design): 디자이너에게 정확한 색 값 확인
abstract final class _ShareColors {
  static const gradientTop = Color(0xFFF5B591);
  static const previewBackground = Color(0x66FBE3D3);
  static const chipBackground = Color(0xFFFCE9DE);
  static const accent = Color(0xFFF08A4B);
  static const icon = Color(0xFF6A6763);
  static const linkIconBackground = Color(0xFFF5F5F5);
}
