import 'dart:math';
import 'package:flutter/material.dart';

/// Lightweight, self-disposing confetti burst (~30 particles, < 1.5s).
class ConfettiBurst extends StatefulWidget {
  final Duration duration;

  const ConfettiBurst({
    super.key,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  static const _colors = [
    Color(0xFFFFD700), // Gold
    Color(0xFFFF6B6B), // Coral
    Color(0xFF4ECDC4), // Teal
    Color(0xFF45B7D1), // Sky
    Color(0xFF96CEB4), // Mint
    Color(0xFFFFBE0B), // Amber
    Color(0xFF8338EC), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();

    final rnd = Random();
    _particles = List.generate(32, (i) {
      final angle = rnd.nextDouble() * 2 * pi;
      final speed = 120.0 + rnd.nextDouble() * 260.0;
      final size = 4.0 + rnd.nextDouble() * 4.0;
      final color = _colors[i % _colors.length];
      return _Particle(
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 60.0, // slight upward bias
        size: size,
        color: color,
        rotation: rnd.nextDouble() * 2 * pi,
        rotationSpeed: (rnd.nextDouble() - 0.5) * 8.0,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isCompleted) return const SizedBox.shrink();
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;

  _Particle({
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.35; // burst from upper-middle
    final t = progress;
    final alpha = (1.0 - t).clamp(0.0, 1.0);

    for (final p in particles) {
      final x = cx + p.vx * t;
      // vy * t + 0.5 * gravity * t^2
      final y = cy + (p.vy * t) + (350.0 * t * t);

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
