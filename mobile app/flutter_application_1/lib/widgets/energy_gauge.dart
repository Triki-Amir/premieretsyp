import 'package:flutter/material.dart';
import 'dart:math';

class EnergyGauge extends StatelessWidget {
  final double value;
  final double max;
  final String label;
  final Color color;
  final String unit;

  const EnergyGauge({
    super.key,
    required this.value,
    required this.max,
    required this.label,
    required this.color,
    this.unit = 'kWh',
  });

  @override
  Widget build(BuildContext context) {
    final percentage = min(value / max, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 144,
          height: 144,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(144, 144),
                painter: CircularGaugePainter(
                  percentage: percentage,
                  color: color,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value.round().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class CircularGaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  CircularGaugePainter({
    required this.percentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * percentage;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
