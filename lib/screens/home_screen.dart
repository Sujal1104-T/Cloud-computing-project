import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import 'quiz_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName?.split(' ')[0] ?? 'User';

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
              final points = userData?['total_score']?.toString() ?? '0';
              final quizzes = userData?['quizzes_taken']?.toString() ?? '0';

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $displayName! 👋',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Ready to test your knowledge?',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (_, animation, __) => const ProfileScreen(),
                                transitionsBuilder: (_, animation, __, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'profile_avatar',
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.neonBlue.withOpacity(0.4),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .slideY(begin: -0.3, end: 0, duration: 600.ms)
                        .fadeIn(duration: 600.ms),

                    const SizedBox(height: 28),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                            child: _StatCard(
                                icon: Icons.emoji_events_rounded,
                                label: 'Points',
                                value: points,
                                color: AppColors.gold)),
                        const SizedBox(width: 14),
                        Expanded(
                            child: _StatCard(
                                icon: Icons.local_fire_department_rounded,
                                label: 'Streak',
                                value: '0 days',
                                color: const Color(0xFFFF6B35))),
                        const SizedBox(width: 14),
                        Expanded(
                            child: _StatCard(
                                icon: Icons.check_circle_rounded,
                                label: 'Quizzes',
                                value: quizzes,
                                color: AppColors.success)),
                      ],
                    )
                        .animate()
                        .slideY(begin: 0.3, end: 0, duration: 600.ms, delay: 150.ms)
                        .fadeIn(duration: 600.ms, delay: 150.ms),

                    const SizedBox(height: 30),

                    // Categories heading
                    Text(
                      'Choose Category',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    )
                        .animate()
                        .slideX(begin: -0.2, end: 0, duration: 500.ms, delay: 200.ms)
                        .fadeIn(duration: 500.ms, delay: 200.ms),

                    const SizedBox(height: 16),

                    // Category Cards from Firestore
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('categories')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No categories found',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          );
                        }

                        final categoryDocs = snapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categoryDocs.length,
                          itemBuilder: (context, index) {
                            final data = categoryDocs[index].data() as Map<String, dynamic>;
                            final title = data['title'] ?? 'Unknown';
                            final subtitle = data['subtitle'] ?? '';
                            final iconName = data['icon'] ?? 'quiz';
                            final colorHex = data['color'] ?? '0xFF00C6FF';
                            
                            final category = {
                              'id': categoryDocs[index].id,
                              'title': title,
                              'subtitle': subtitle,
                              'icon': _getIconData(iconName),
                              'color': Color(int.parse(colorHex)),
                              'difficulty': data['difficulty'] ?? 'Beginner',
                            };

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _CategoryCard(
                                category: category,
                                onTap: () => Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (_, animation, __) =>
                                        QuizScreen(
                                      category: title,
                                      categoryId: categoryDocs[index].id,
                                    ),
                                    transitionsBuilder: (_, animation, __, child) {
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(1.0, 0.0),
                                          end: Offset.zero,
                                        ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic)),
                                        child: FadeTransition(
                                            opacity: animation, child: child),
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 500),
                                  ),
                                ),
                              )
                                  .animate()
                                  .slideX(
                                    begin: 0.4,
                                    end: 0,
                                    duration: 600.ms,
                                    delay: Duration(milliseconds: 300 + index * 120),
                                    curve: Curves.easeOutCubic,
                                  )
                                  .fadeIn(
                                    duration: 600.ms,
                                    delay: Duration(milliseconds: 300 + index * 120),
                                  ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // Start Quiz button
                    GlowButton(
                      text: 'Start Random Quiz',
                      width: double.infinity,
                      height: 60,
                      onPressed: () => Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, animation, __) =>
                              const QuizScreen(category: 'Mixed', categoryId: 'mixed'),
                          transitionsBuilder: (_, animation, __, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 24),
                    )
                        .animate()
                        .slideY(begin: 0.4, end: 0, duration: 600.ms, delay: 700.ms)
                        .fadeIn(duration: 600.ms, delay: 700.ms),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'cloud':
        return Icons.cloud_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'terminal':
        return Icons.terminal_rounded;
      case 'calculate':
        return Icons.calculate_rounded;
      default:
        return Icons.quiz_rounded;
    }
  }
}

// Removed static _categories list as per instruction.
// Categories are now fetched dynamically from Firestore.

class _CategoryCard extends StatefulWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.category['color'] as Color? ?? const Color(0xFF00C6FF);
    final gradient = LinearGradient(
      colors: [baseColor, baseColor.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient.colors
                  .map((c) => (c).withOpacity(0.18))
                  .toList(),
              begin: gradient.begin,
              end: gradient.end,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color:
                  (gradient.colors.first).withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (gradient.colors.first).withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (gradient.colors.first).withOpacity(0.4),
                      blurRadius: 12,
                    )
                  ],
                ),
                child: Icon(
                  widget.category['icon'] as IconData,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.category['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.category['subtitle'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.textMuted, size: 16),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (gradient.colors.first).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: (gradient.colors.first)
                              .withOpacity(0.4)),
                    ),
                    child: Text(
                      widget.category['difficulty'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: gradient.colors.first,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
