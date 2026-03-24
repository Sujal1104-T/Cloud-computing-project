import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final name = userData?['name'] ?? user.displayName ?? 'User';
              final email = userData?['email'] ?? user.email ?? 'No email';
              final totalScore = userData?['total_score'] ?? 0;
              final quizzesTaken = userData?['quizzes_taken'] ?? 0;
              final String rank = _calculateRank(totalScore);

              final timestamp = userData?['createdAt'] as Timestamp?;
              final joinDate = timestamp != null
                  ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
                  : 'Recently';

              return Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.glassWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppColors.textPrimary, size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Player Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .slideY(begin: -0.3, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          
                          // Avatar & Name Card
                          GlassCard(
                            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                            child: Column(
                              children: [
                                Hero(
                                  tag: 'profile_avatar',
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppColors.primaryGradient,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.neonBlue.withOpacity(0.4),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        name.isNotEmpty
                                            ? name.substring(0, 1).toUpperCase()
                                            : 'U',
                                        style: GoogleFonts.poppins(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.neonBlue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.neonBlue.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    'Joined $joinDate',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.neonBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .scale(
                                  begin: const Offset(0.9, 0.9),
                                  end: const Offset(1, 1),
                                  duration: 600.ms,
                                  curve: Curves.easeOutBack)
                              .fadeIn(duration: 600.ms),

                          const SizedBox(height: 24),

                          // Stats Grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.2,
                            children: [
                              _ProfileStatCard(
                                icon: Icons.emoji_events_rounded,
                                label: 'Total Score',
                                value: totalScore.toString(),
                                color: AppColors.gold,
                              ),
                              _ProfileStatCard(
                                icon: Icons.shield_rounded,
                                label: 'Current Rank',
                                value: rank,
                                color: AppColors.neonBlue,
                              ),
                              _ProfileStatCard(
                                icon: Icons.quiz_rounded,
                                label: 'Quizzes Taken',
                                value: quizzesTaken.toString(),
                                color: AppColors.success,
                              ),
                              _ProfileStatCard(
                                icon: Icons.local_fire_department_rounded,
                                label: 'Best Subject',
                                value: userData?['last_category'] ?? 'None',
                                color: const Color(0xFFFF6B35),
                              ),
                            ],
                          )
                              .animate()
                              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 200.ms)
                              .fadeIn(duration: 600.ms, delay: 200.ms),

                          const SizedBox(height: 40),

                          // Logout Button
                          GlowButton(
                            text: 'Log Out',
                            height: 56,
                            outlined: true,
                            glowColor: AppColors.error,
                            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => const LoginScreen(),
                                    transitionsBuilder: (_, animation, __, child) =>
                                        FadeTransition(opacity: animation, child: child),
                                    transitionDuration: const Duration(milliseconds: 400),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                          )
                              .animate()
                              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 400.ms)
                              .fadeIn(duration: 600.ms, delay: 400.ms),
                              
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _calculateRank(int score) {
    if (score >= 50) return 'Master';
    if (score >= 30) return 'Expert';
    if (score >= 10) return 'Pro';
    return 'Amateur';
  }
}

class _ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProfileStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
