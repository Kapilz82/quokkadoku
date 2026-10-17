import 'dart:math';
import 'package:flutter/material.dart';

/// Lächelndes Quokka, hüpft beim Erscheinen.
class Quokka extends StatelessWidget {
  const Quokka({super.key});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.elasticOut,
        builder: (_, t, child) => Transform.scale(
          scale: t,
          child: Transform.rotate(angle: (1 - t) * 0.6, child: child),
        ),
        child: const CustomPaint(painter: _QuokkaPainter(), child: SizedBox.expand()),
      );
}

class _QuokkaPainter extends CustomPainter {
  const _QuokkaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final ox = (size.width - s) / 2, oy = (size.height - s) / 2;
    Offset p(double x, double y) => Offset(ox + x * s, oy + y * s);
    final fur = Paint()..color = const Color(0xFFA67C52);
    final furDark = Paint()..color = const Color(0xFF8A6442);
    final belly = Paint()..color = const Color(0xFFD9B99B);
    final dark = Paint()..color = const Color(0xFF3B2A20);
    final line = Paint()
      ..color = const Color(0xFF3B2A20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round;

    // Schwanz (dünn, nach hinten)
    canvas.drawPath(
        Path()
          ..moveTo(p(0.22, 0.72).dx, p(0.22, 0.72).dy)
          ..quadraticBezierTo(p(0.02, 0.78).dx, p(0.02, 0.78).dy, p(0.06, 0.62).dx, p(0.06, 0.62).dy),
        Paint()
          ..color = const Color(0xFF8A6442)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.06
          ..strokeCap = StrokeCap.round);
    // Körper (sitzend, rund)
    canvas.drawOval(Rect.fromCenter(center: p(0.40, 0.66), width: s * 0.52, height: s * 0.46), fur);
    canvas.drawOval(Rect.fromCenter(center: p(0.46, 0.72), width: s * 0.30, height: s * 0.26), belly);
    // Hinterfuß + Vorderpfote
    canvas.drawOval(Rect.fromCenter(center: p(0.30, 0.88), width: s * 0.22, height: s * 0.09), furDark);
    canvas.drawOval(Rect.fromCenter(center: p(0.58, 0.86), width: s * 0.14, height: s * 0.08), furDark);
    // Kopf (rechts, Profil)
    canvas.drawCircle(p(0.64, 0.40), s * 0.22, fur);
    // Ohr
    canvas.drawCircle(p(0.56, 0.22), s * 0.09, furDark);
    canvas.drawCircle(p(0.56, 0.22), s * 0.05, Paint()..color = const Color(0xFFF2C6B4));
    // Schnauze
    canvas.drawOval(Rect.fromCenter(center: p(0.80, 0.46), width: s * 0.22, height: s * 0.17), belly);
    // Auge
    canvas.drawCircle(p(0.70, 0.37), s * 0.045, dark);
    canvas.drawCircle(p(0.715, 0.355), s * 0.014, Paint()..color = Colors.white);
    // Nase
    canvas.drawCircle(p(0.89, 0.43), s * 0.035, dark);
    // Das berühmte Lächeln
    canvas.drawPath(
        Path()
          ..moveTo(p(0.76, 0.50).dx, p(0.76, 0.50).dy)
          ..quadraticBezierTo(p(0.84, 0.58).dx, p(0.84, 0.58).dy, p(0.90, 0.50).dx, p(0.90, 0.50).dy),
        line);
    // Wange
    canvas.drawCircle(p(0.74, 0.50), s * 0.045, Paint()..color = const Color(0x55FF8A80));
  }

  @override
  bool shouldRepaint(_QuokkaPainter old) => false;
}

/// Schwebende "+Punkte"-Zahl, steigt auf und verblasst.
class FloatingPoints extends StatelessWidget {
  final int points;
  final VoidCallback onDone;
  const FloatingPoints({super.key, required this.points, required this.onDone});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOut,
        onEnd: onDone,
        builder: (_, t, child) => Opacity(
          opacity: 1 - t,
          child: Transform.translate(offset: Offset(0, -40 * t), child: child),
        ),
        child: Text(
          '+$points',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFE65100),
            shadows: [Shadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 6)],
          ),
        ),
      );
}

/// Konfetti-Herzchen fürs Gewinnen – nur ein bisschen Zucker.
class Sparkle extends StatelessWidget {
  final int seed;
  const Sparkle({super.key, required this.seed});
  @override
  Widget build(BuildContext context) {
    final rng = Random(seed);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      builder: (_, t, child) => Opacity(
        opacity: 1 - t,
        child: Transform.translate(
          offset: Offset((rng.nextDouble() - 0.5) * 120 * t, -90 * t),
          child: Text(['💛', '🌿', '✨', '🧡'][seed % 4], style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}
