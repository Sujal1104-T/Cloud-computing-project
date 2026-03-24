import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../constants/app_colors.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int total;
  final String category;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.category,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    Future.delayed(const Duration(milliseconds: 500), () {
      _confettiController.play();
    });
    _saveScore();
  }

  Future<void> _saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        if (!snapshot.exists) return;

        final currentScore = snapshot.get('total_score') ?? 0;
        final currentQuizzes = snapshot.get('quizzes_taken') ?? 0;

        transaction.update(userDoc, {
          'total_score': currentScore + widget.score,
          'quizzes_taken': currentQuizzes + 1,
          'last_quiz_at': FieldValue.serverTimestamp(),
          'last_category': widget.category,
        });
      });
    } catch (e) {
      debugPrint('Error saving score: $e');
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String get _grade {
    final pct = widget.score / widget.total;
    if (pct >= 0.9) return 'S';
    if (pct >= 0.7) return 'A';
    if (pct >= 0.5) return 'B';
    if (pct >= 0.3) return 'C';
    return 'D';
  }

  String get _message {
    final pct = widget.score / widget.total;
    if (pct >= 0.9) return 'Outstanding! 🏆';
    if (pct >= 0.7) return 'Great Job! 🎉';
    if (pct >= 0.5) return 'Well Done! 👍';
    return 'Keep Practicing! 💪';
  }

  Color get _gradeColor {
    final pct = widget.score / widget.total;
    if (pct >= 0.9) return AppColors.gold;
    if (pct >= 0.7) return AppColors.success;
    if (pct >= 0.5) return AppColors.neonBlue;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.score / widget.total;

    return Scaffold(
      body: AnimatedBackground(
        child: Stack(
          children: [
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 40,
                maxBlastForce: 50,
                minBlastForce: 20,
                emissionFrequency: 0.05,
                gravity: 0.3,
                colors: const [
                  AppColors.neonBlue,
                  AppColors.deepPurple,
                  AppColors.gold,
                  AppColors.success,
                  Colors.white,
                ],
              ),
            ),

            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // Title
                    Text(
                      _message,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    )
                        .animate()
                        .slideY(begin: -0.3, end: 0, duration: 600.ms)
                        .fadeIn(duration: 600.ms),

                    const SizedBox(height: 8),
                    Text(
                      'Quiz completed — ${widget.category}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

                    const SizedBox(height: 36),

                    // Score Circle
                    GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          CircularPercentIndicator(
                            radius: 90,
                            lineWidth: 12,
                            percent: pct,
                            animation: true,
                            animationDuration: 1500,
                            circularStrokeCap: CircularStrokeCap.round,
                            progressColor: _gradeColor,
                            backgroundColor:
                                _gradeColor.withOpacity(0.15),
                            center: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${widget.score}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w800,
                                    color: _gradeColor,
                                  ),
                                ).animate().scale(
                                    begin: const Offset(0.5, 0.5),
                                    end: const Offset(1.0, 1.0),
                                    duration: 800.ms,
                                    delay: 400.ms,
                                    curve: Curves.elasticOut,
                                  ),
                                Text(
                                  'of ${widget.total}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Grade Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: _gradeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _gradeColor.withOpacity(0.5),
                                  width: 1.5),
                            ),
                            child: Text(
                              'Grade: $_grade',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _gradeColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _QuickStat(
                                  label: 'Correct',
                                  value: '${widget.score}',
                                  color: AppColors.success),
                              _QuickStat(
                                  label: 'Wrong',
                                  value: '${widget.total - widget.score}',
                                  color: AppColors.error),
                              _QuickStat(
                                  label: 'Accuracy',
                                  value: '${(pct * 100).toStringAsFixed(0)}%',
                                  color: AppColors.neonBlue),
                            ],
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                          duration: 700.ms,
                          delay: 300.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 500.ms, delay: 300.ms),

                    const Spacer(),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GlowButton(
                            text: 'Retry',
                            height: 56,
                            outlined: true,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.refresh_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GlowButton(
                            text: 'Leaderboard',
                            height: 56,
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.deepPurple,
                                AppColors.neonBlue
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            onPressed: () =>
                                Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (_, animation, __) =>
                                    const LeaderboardScreen(),
                                transitionsBuilder:
                                    (_, animation, __, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 1.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic)),
                                    child: child,
                                  );
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 500),
                              ),
                            ),
                            icon: const Icon(Icons.leaderboard_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .slideY(begin: 0.4, end: 0, duration: 600.ms, delay: 600.ms)
                        .fadeIn(duration: 600.ms, delay: 600.ms),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .pushAndRemoveUntil(
                        PageRouteBuilder(
                          pageBuilder: (_, animation, __) =>
                              const HomeScreen(),
                          transitionsBuilder:
                              (_, animation, __, child) =>
                                  FadeTransition(
                                      opacity: animation, child: child),
                          transitionDuration:
                              const Duration(milliseconds: 400),
                        ),
                        (route) => false,
                      ),
                      child: Text(
                        'Back to Home',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 800.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _QuickStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
