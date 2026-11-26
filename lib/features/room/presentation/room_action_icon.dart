import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// The shared 46px circle used by room edit and share actions.
class RoomActionIcon extends StatelessWidget {
  const RoomActionIcon({super.key, this.edit = false});
  final bool edit;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 46,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        shape: BoxShape.circle,
      ),
      child: CustomPaint(painter: _ActionPainter(edit)),
    ),
  );
}

class _ActionPainter extends CustomPainter {
  const _ActionPainter(this.edit);
  final bool edit;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 46, size.height / 46);
    if (edit) {
      final base = Path()
        ..moveTo(12.56, 29.16)
        ..lineTo(23.01, 35.25)
        ..lineTo(33.41, 29.24)
        ..lineTo(22.96, 23.16)
        ..close();
      canvas.drawPath(base, Paint()..color = Colors.black);
      final top = Path()
        ..moveTo(33.34, 17.16)
        ..lineTo(22.91, 11.06)
        ..lineTo(12.51, 17.06)
        ..lineTo(12.56, 29.16)
        ..lineTo(22.96, 23.16)
        ..lineTo(33.41, 29.24)
        ..close();
      canvas.drawPath(
        top,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFF813B), Color(0xFFFFB43B)],
          ).createShader(const Rect.fromLTWH(12.5, 11, 21, 24)),
      );
    } else {
      final paint = Paint()
        ..color = const Color(0xFF212529)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawLine(const Offset(19.4, 22), const Offset(26.6, 18.4), paint);
      canvas.drawLine(const Offset(19.4, 24), const Offset(26.6, 27.6), paint);
      for (final center in const [
        Offset(17.5, 23),
        Offset(28.5, 17.5),
        Offset(28.5, 28.5),
      ]) {
        canvas.drawCircle(center, 2, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ActionPainter oldDelegate) => edit != oldDelegate.edit;
}
