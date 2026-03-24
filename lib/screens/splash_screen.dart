import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../widgets/animated_background.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const LoginScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo Container
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.neonBlue, AppColors.deepPurple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonBlue.withOpacity(
                                0.3 + _pulseController.value * 0.4),
                            blurRadius: 30 + _pulseController.value * 30,
                            spreadRadius: 5 + _pulseController.value * 10,
                          ),
                          BoxShadow(
                            color: AppColors.deepPurple.withOpacity(
                                0.2 + _pulseController.value * 0.3),
                            blurRadius: 50,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: const Icon(
                    Icons.quiz_rounded,
                    size: 70,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.0, 0.0),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 40),

                // App Name
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: Text(
                    'QuizMaster',
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                )
                    .animate()
                    .slideY(
                      begin: 0.5,
                      end: 0,
                      duration: 800.ms,
                      delay: 300.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fadeIn(duration: 600.ms, delay: 300.ms),

                const SizedBox(height: 12),

                // Tagline
                Text(
                  'Test Your Knowledge Instantly',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .slideY(
                      begin: 0.5,
                      end: 0,
                      duration: 800.ms,
                      delay: 500.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fadeIn(duration: 600.ms, delay: 500.ms),

                const SizedBox(height: 80),

                // Loading indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.neonBlue.withOpacity(0.7),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 1000.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
