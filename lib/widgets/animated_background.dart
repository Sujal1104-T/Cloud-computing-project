import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );

    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(random: _random));
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_particleController, _gradientAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(const Color(0xFF0F172A), const Color(0xFF1A0A2E),
                    _gradientAnimation.value)!,
                Color.lerp(const Color(0xFF1A0A2E), const Color(0xFF0F1F3A),
                    _gradientAnimation.value)!,
                const Color(0xFF0F172A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Glow orbs
              Positioned(
                top: -100 + (_gradientAnimation.value * 40),
                left: -80,
                child: _GlowOrb(
                  size: 300,
                  color: AppColors.deepPurple.withOpacity(0.15),
                ),
              ),
              Positioned(
                bottom: -80 + (_gradientAnimation.value * 30),
                right: -60,
                child: _GlowOrb(
                  size: 260,
                  color: AppColors.neonBlue.withOpacity(0.12),
                ),
              ),
              // Particles
              CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
                child: const SizedBox.expand(),
              ),
              // Content
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 120, spreadRadius: 40),
        ],
      ),
    );
  }
}

class _Particle {
  late double x;
  late double y;
  late double size;
  late double opacity;
  late double speed;
  late double angle;

  _Particle({required Random random}) {
    x = random.nextDouble();
    y = random.nextDouble();
    size = random.nextDouble() * 3 + 1;
    opacity = random.nextDouble() * 0.5 + 0.1;
    speed = random.nextDouble() * 0.002 + 0.001;
    angle = random.nextDouble() * 2 * pi;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = (p.x + cos(p.angle) * progress * p.speed * 10) % 1.0;
      final y = (p.y + sin(p.angle) * progress * p.speed * 10) % 1.0;
      final paint = Paint()
        ..color = AppColors.neonBlue.withOpacity(p.opacity * 0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size);

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
