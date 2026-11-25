import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class GuideBookIcon extends StatelessWidget {
  const GuideBookIcon({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 46,
    height: 46,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        shape: BoxShape.circle,
      ),
      child: CustomPaint(painter: _BookPainter()),
    ),
  );
}

class _BookPainter extends CustomPainter {
  const _BookPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 46, size.height / 46);
    final pen = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.15
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(30.38, 32.98)
        ..lineTo(16.38, 32.98)
        ..quadraticBezierTo(14.38, 32.98, 14.38, 30.98)
        ..lineTo(14.38, 14.98)
        ..quadraticBezierTo(14.38, 12.98, 16.38, 12.98)
        ..lineTo(30.38, 12.98)
        ..close(),
      pen,
    );
    canvas.drawPath(
      Path()
        ..moveTo(30.38, 28.98)
        ..lineTo(16.38, 28.98)
        ..quadraticBezierTo(14.38, 28.98, 14.38, 30.98),
      pen,
    );
    for (final y in [18.98, 22.98]) {
      canvas.drawLine(Offset(18.38, y), Offset(26.38, y), pen);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
