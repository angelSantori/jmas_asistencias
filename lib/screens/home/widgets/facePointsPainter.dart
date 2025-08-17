import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class FacePointsPainter extends CustomPainter {
  final List<img.Point> points;

  FacePointsPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(
        Offset(point.x.toDouble(), point.y.toDouble()),
        4,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
