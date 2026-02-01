import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for rotating Bagua (octagon) reticle
class BaguaPainter extends CustomPainter {
  final double rotation;
  final Color color;
  
  BaguaPainter({
    required this.rotation,
    this.color = const Color(0xFFD6BCFA), // Default to soft lavender if not provided
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Draw octagon (8 sides for Bagua)
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + rotation;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Draw glow
    canvas.drawPath(path, glowPaint);
    // Draw main octagon
    canvas.drawPath(path, paint);

    // Draw center crosshair
    final crosshairPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(center.dx - 20, center.dy),
      Offset(center.dx + 20, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 20),
      Offset(center.dx, center.dy + 20),
      crosshairPaint,
    );

    // Draw corner markers
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + rotation;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(BaguaPainter oldDelegate) =>
      rotation != oldDelegate.rotation || color != oldDelegate.color;
}
