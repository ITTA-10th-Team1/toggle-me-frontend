import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_notice.dart';

const _orange = Color(0xFFFF813B);
const _chipBorder = Color(0xFFFD8E51);
const _ink = Color(0xFF171717);

Future<void> showUsageGuide(
  BuildContext context, {
  Future<void> Function()? onComplete,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  barrierColor: Colors.black38,
  useSafeArea: false,
  builder: (_) => UsageGuideScreen(onComplete: onComplete),
);

class UsageGuideScreen extends StatefulWidget {
  const UsageGuideScreen({super.key, this.onComplete, this.nickname = 'OO'});
  final Future<void> Function()? onComplete;
  final String nickname;
  @override
  State<UsageGuideScreen> createState() => _UsageGuideScreenState();
}

class _UsageGuideScreenState extends State<UsageGuideScreen> {
  int page = 0;
  bool saving = false;
  static const titles = [
    '�����ϴ� �͵�� ä��� ������ ����',
    '������ ��� ������ ���� �ٸ纸����',
    'ī�װ������� ������ ��ƺ�����',
    '���� ��� �ӿ��� ���� ������ �߰��ؿ�',
    'ģ���� ������ �����ؿ�',
  ];
  static const descriptions = [
    '����۹̡��� ���� �����ϴ� �͵��� ���\n���� �ϳ����� ������ ���� ����� �����̿���.',
    '�پ��� �������� ������ ���ϴ� ��ġ�� ��ġ�ϸ�\n������ ������ �����Ӱ� �ٸ纸����.',
    '����, �м�, ��ȭ �� ī�װ������� ���� ������\n���� �����ϴ� �͵��� ����غ�����.\n�ϳ��� ä����� ������ ���� �ϼ��ſ�!',
    '���� ���� ��ϵ��� AI�� �м���\n������ ����� Ư¡�� �˷� �� �ſ���.',
    '���ݱ��� ���� ���� ���� �ؽ��±׸�\nģ������ ������ �� �־��.',
  ];

  Future<void> next() async {
    if (saving) return;
    if (page < 4) {
      setState(() => page++);
      return;
    }
    setState(() => saving = true);
    try {
      await widget.onComplete?.call();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showAppNotice(context, '�Ϸ� ������ �������� ���߾��. �ٽ� �õ��� �ּ���.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(
              360.0,
              math.max(0.0, constraints.maxWidth - 16),
            );
            const height = 590.0;
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFFFAF82),
                              Color(0xFFFFF9F0),
                              Colors.white,
                              Colors.white,
                            ],
                            stops: [0, 0.56, 0.65, 1],
                          ),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 42,
                              child: Center(
                                child: Semantics(
                                  label: '�̿밡�̵� ${page + 1} / 5',
                                  liveRegion: true,
                                  child: ExcludeSemantics(
                                    child: SizedBox(
                                      width: math.min(291, width - 32),
                                      child: Row(
                                        children: List.generate(
                                          5,
                                          (i) => Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                right: i == 4 ? 0 : 4,
                                              ),
                                              child: Container(
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: i == page
                                                      ? _orange
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  8,
                                  18,
                                  16,
                                ),
                                child: Center(
                                  child: _GuideArtwork(
                                    page: page,
                                    nickname: widget.nickname,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    titles[page],
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.head2.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _GuideDescription(text: descriptions[page]),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (page > 0) ...[
                                  SizedBox(
                                    width: 53,
                                    height: 53,
                                    child: OutlinedButton(
                                      onPressed: saving
                                          ? null
                                          : () => setState(() => page--),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        backgroundColor: const Color(
                                          0xFFF5F5F5,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF545454,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFD5D5D5),
                                        ),
                                        shape: const CircleBorder(),
                                      ),
                                      child: const Tooltip(
                                        message: '����',
                                        child: Icon(Icons.arrow_back, size: 24),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 29),
                                ],
                                SizedBox(
                                  width: 157,
                                  height: 53,
                                  child: FilledButton(
                                    onPressed: saving ? null : next,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _ink,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: _ink,
                                      padding: EdgeInsets.zero,
                                      shape: const StadiumBorder(),
                                    ),
                                    child: saving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            page == 4 ? '�� ������' : '����',
                                            style: AppTextStyles.head3.copyWith(
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _GuideArtwork extends StatelessWidget {
  const _GuideArtwork({required this.page, required this.nickname});
  final int page;
  final String nickname;
  @override
  Widget build(BuildContext context) => MediaQuery.withNoTextScaling(
    child: Semantics(
      image: true,
      label: const [
        '������ �� ����',
        '�پ��� ���� ����',
        '���� ī�װ����� ��� ����',
        '����� �м��� ���� �±׸� ����� ����',
        '���� �ؽ��±� ���� ����',
      ][page],
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 303,
            height: 300,
            child: switch (page) {
              0 => Center(
                child: Image.asset(
                  'assets/guide/room.webp',
                  width: 254,
                  height: 215,
                ),
              ),
              1 => Center(
                child: Image.asset(
                  'assets/guide/furniture.webp',
                  width: 277,
                  height: 250,
                ),
              ),
              2 => const _CategoryArt(),
              3 => const _AnalysisArt(),
              _ => _ShareArt(nickname: nickname),
            },
          ),
        ),
      ),
    ),
  );
}

class _CategoryArt extends StatelessWidget {
  const _CategoryArt();
  Widget card(String label, String? image) => Container(
    width: 90,
    height: 90,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      mainAxisAlignment: image == null
          ? MainAxisAlignment.end
          : MainAxisAlignment.center,
      children: [
        if (image != null)
          Image.asset(image, width: 42, height: 48, fit: BoxFit.contain),
        const SizedBox(height: 5),
        Text(label, style: AppTextStyles.body2.copyWith(color: Colors.black)),
        if (image == null) const SizedBox(height: 5),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.hardEdge,
    children: [
      Positioned(
        left: 0,
        top: -70,
        child: Opacity(opacity: 0.5, child: card('å��', null)),
      ),
      Positioned(
        left: 0,
        top: 33,
        child: card('�ſ�', 'assets/room/raster/mirror_color.png'),
      ),
      Positioned(
        left: 0,
        top: 137,
        child: card('�����', 'assets/room/raster/fridge_color.png'),
      ),
      const Positioned(
        left: 89,
        top: 126,
        width: 45,
        height: 70,
        child: CustomPaint(painter: _ConnectorPainter()),
      ),
      Positioned(
        left: 130,
        top: 30,
        child: Container(
          width: 160,
          height: 197,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Pill(text: '����', filled: true, width: 84),
              const SizedBox(height: 10),
              for (final text in ['������', '���� ����ũ', '�Ƹ޸�ī��'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        color: _orange,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        text,
                        style: AppTextStyles.body2.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Container(
                height: 33,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF767676)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, size: 16, color: Color(0xFF767676)),
                      const SizedBox(width: 5),
                      Text(
                        '����ϱ�',
                        style: AppTextStyles.body2.copyWith(
                          color: const Color(0xFF767676),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _AnalysisArt extends StatelessWidget {
  const _AnalysisArt();
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Pill(text: '���� ����ũ', heart: true),
          SizedBox(width: 14),
          _Pill(text: 'LP�÷��̾�', heart: true),
        ],
      ),
      const SizedBox(height: 6),
      const _Pill(text: '���̾��', heart: true),
      const SizedBox(height: 18),
      Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _orange),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: _orange, size: 27),
            const SizedBox(height: 5),
            Text(
              'AI �м�',
              style: AppTextStyles.body2.copyWith(color: Colors.black),
            ),
          ],
        ),
      ),
      const SizedBox(
        height: 18,
        width: 1,
        child: CustomPaint(painter: _VerticalDotsPainter()),
      ),
      const _Pill(text: '#������ȭ', outlined: true),
      const SizedBox(height: 6),
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Pill(text: '#���ϵ���Ʈ', outlined: true),
          SizedBox(width: 14),
          _Pill(text: '#��Ƽ������', outlined: true),
        ],
      ),
    ],
  );
}

class _ShareArt extends StatelessWidget {
  const _ShareArt({required this.nickname});
  final String nickname;
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 291,
      height: 238,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _chipBorder.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OO���� ȭ��',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body2.copyWith(color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  for (final text in ['#������ȭ', '#���ϵ���Ʈ', '#��Ƽ������'])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _Pill(text: text, outlined: true),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: const BoxDecoration(
                  color: _orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.share_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '�����ϱ�',
                style: AppTextStyles.body2.copyWith(color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    this.heart = false,
    this.outlined = false,
    this.filled = false,
    this.width,
  });
  final String text;
  final bool heart, outlined, filled;
  final double? width;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    constraints: const BoxConstraints(minHeight: 34),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    decoration: BoxDecoration(
      color: filled
          ? _orange
          : outlined
          ? const Color(0xFFFFE9DB)
          : const Color(0xFFFFF9F0),
      border: outlined ? Border.all(color: _chipBorder) : null,
      borderRadius: BorderRadius.circular(200),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (heart) ...[
          const Icon(Icons.favorite_border, size: 14, color: _orange),
          const SizedBox(width: 7),
        ],
        Text(
          text,
          style: AppTextStyles.body2.copyWith(
            color: filled ? Colors.white : Colors.black,
            height: 1.125,
          ),
        ),
      ],
    ),
  );
}

class _ConnectorPainter extends CustomPainter {
  const _ConnectorPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _ink
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(0, size.height), 2.5, p);
    for (double y = 0; y < size.height; y += 8) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, math.min(y + 4, size.height)),
        p,
      );
    }
    for (double x = 0; x < size.width; x += 8) {
      final y = x < size.width / 2 ? size.height : 0.0;
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VerticalDotsPainter extends CustomPainter {
  const _VerticalDotsPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _ink
      ..strokeWidth = 1;
    for (double y = 0; y < size.height - 4; y += 5) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 2), p);
    }
    canvas.drawCircle(Offset(0, size.height - 2), 2.5, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Preserve the designer's explicit lines at standard text size. Larger system
/// text keeps normal wrapping so accessibility settings remain useful.
class _GuideDescription extends StatelessWidget {
  const _GuideDescription({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.body2.copyWith(
      color: Colors.black,
      height: 1.375,
    );
    if (MediaQuery.textScalerOf(context).scale(16) > 16) {
      return Text(text, textAlign: TextAlign.center, style: style);
    }
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            for (final line in text.split('\n')) Text(line, style: style),
          ],
        ),
      ),
    );
  }
}
