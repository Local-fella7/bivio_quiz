import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Celebratory flower-burst overlay displayed on [ResultsScreen] whenever
/// the user scores over 50%.
///
/// Uses a single finite [AnimationController] (2.8 seconds) and a [CustomPainter]
/// to pop out colorful 5-petal flowers and sparkles that arc upward, spin gently,
/// drift down with gravity, and fade out—wrapped in [IgnorePointer] so it never
/// blocks button taps underneath.
class CelebrationFlowers extends StatefulWidget {
  const CelebrationFlowers({super.key});

  @override
  State<CelebrationFlowers> createState() => _CelebrationFlowersState();
}

class _CelebrationFlowersState extends State<CelebrationFlowers>
    with SingleTickerProviderStateMixin {
  /// Drives the entire flower burst from `0.0` (pop) to `1.0` (faded out).
  late final AnimationController _controller;

  /// Pre-generated deterministic particle descriptors so flowers animate smoothly.
  late final List<_FlowerParticle> _particles;

  /// Festive petal color palette that pops crisply against the blue gradient.
  static const List<Color> _petalPalette = [
    Color(0xFFFF80AB), // Blossom pink
    Color(0xFFFFD54F), // Sunny marigold
    Color(0xFF69F0AE), // Mint green
    Color(0xFFF8FAE5), // Warm cream
    Color(0xFFFFAB91), // Coral peach
    Color(0xFFEA80FC), // Lavender blossom
  ];

  @override
  void initState() {
    super.initState();

    // Fixed seed gives a balanced, pleasing burst every time without jitter.
    final random = math.Random(42);
    _particles = List.generate(34, (index) {
      // Spread launch angles across a wide upward fan (-155° to -25°).
      final angle = -math.pi * (0.14 + random.nextDouble() * 0.72);
      final speed = 220 + random.nextDouble() * 340;
      return _FlowerParticle(
        originXFactor: 0.25 + random.nextDouble() * 0.5,
        originYFactor: 0.32 + random.nextDouble() * 0.14,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        size: 11 + random.nextDouble() * 13,
        petalColor: _petalPalette[index % _petalPalette.length],
        centerColor: const Color(0xFFFFF59D),
        rotationSpeed: (random.nextDouble() - 0.5) * 6,
        initialRotation: random.nextDouble() * math.pi * 2,
        delay: random.nextDouble() * 0.22,
        isSparkle: index % 5 == 0,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();
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
          return CustomPaint(
            painter: _FlowerBurstPainter(
              progress: _controller.value,
              particles: _particles,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

/// Immutable physics & appearance properties for a single flower or sparkle.
class _FlowerParticle {
  const _FlowerParticle({
    required this.originXFactor,
    required this.originYFactor,
    required this.vx,
    required this.vy,
    required this.size,
    required this.petalColor,
    required this.centerColor,
    required this.rotationSpeed,
    required this.initialRotation,
    required this.delay,
    required this.isSparkle,
  });

  final double originXFactor;
  final double originYFactor;
  final double vx;
  final double vy;
  final double size;
  final Color petalColor;
  final Color centerColor;
  final double rotationSpeed;
  final double initialRotation;
  final double delay;
  final bool isSparkle;
}

/// CustomPainter that draws each popping 5-petal flower and 4-point sparkle.
class _FlowerBurstPainter extends CustomPainter {
  const _FlowerBurstPainter({
    required this.progress,
    required this.particles,
  });

  /// Overall animation progress (`0.0` → `1.0`).
  final double progress;

  /// List of flower/sparkle particles to render.
  final List<_FlowerParticle> particles;

  /// Downward gravitational acceleration in logical pixels/sec².
  static const double _gravity = 420;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Respect each particle's staggered start delay.
      final localProgress =
          ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (localProgress <= 0 || localProgress >= 1) continue;

      // Elapsed time in seconds for kinematic trajectory calculation.
      final t = localProgress * 2.4;
      final x = (size.width * p.originXFactor) + p.vx * t;
      final y =
          (size.height * p.originYFactor) + p.vy * t + 0.5 * _gravity * t * t;

      // Pop-in scale during the first 15% of life, gentle fade-out in the last 30%.
      final popScale = localProgress < 0.15
          ? Curves.easeOutBack.transform(localProgress / 0.15)
          : 1.0;
      final opacity = localProgress > 0.70
          ? (1.0 - ((localProgress - 0.70) / 0.30)).clamp(0.0, 1.0)
          : 1.0;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.initialRotation + p.rotationSpeed * t);
      canvas.scale(popScale);

      if (p.isSparkle) {
        _drawSparkle(canvas, p.size * 0.75, p.petalColor.withValues(alpha: opacity));
      } else {
        _drawFlower(
          canvas,
          p.size,
          p.petalColor.withValues(alpha: opacity),
          p.centerColor.withValues(alpha: opacity),
        );
      }

      canvas.restore();
    }
  }

  /// Draws a stylized 5-petal blossom centered at `(0, 0)`.
  void _drawFlower(
    Canvas canvas,
    double radius,
    Color petalColor,
    Color centerColor,
  ) {
    final petalPaint = Paint()
      ..color = petalColor
      ..style = PaintingStyle.fill;

    const petalCount = 5;
    final petalRadius = radius * 0.44;
    final petalOffset = radius * 0.46;

    for (var i = 0; i < petalCount; i++) {
      final angle = (i * 2 * math.pi) / petalCount;
      final cx = math.cos(angle) * petalOffset;
      final cy = math.sin(angle) * petalOffset;
      canvas.drawCircle(Offset(cx, cy), petalRadius, petalPaint);
    }

    // Warm yellow flower center.
    final centerPaint = Paint()
      ..color = centerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 0.28, centerPaint);
  }

  /// Draws a crisp 4-point star sparkle centered at `(0, 0)`.
  void _drawSparkle(Canvas canvas, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, -radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..quadraticBezierTo(0, 0, 0, radius)
      ..quadraticBezierTo(0, 0, -radius, 0)
      ..quadraticBezierTo(0, 0, 0, -radius)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FlowerBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
