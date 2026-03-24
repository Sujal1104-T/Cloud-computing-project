import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('total_score', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No leaderboard data yet!'));
              }

              final users = snapshot.data!.docs;
              
              // Process data for the list
              final leaderboardData = users.asMap().entries.map((entry) {
                final index = entry.key;
                final doc = entry.value;
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] ?? 'Anonymous';
                
                return {
                  'rank': index + 1,
                  'name': doc.id == currentUserId ? '$name (You)' : name,
                  'score': data['total_score'] ?? 0,
                  'avatar': name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
                  'isCurrentUser': doc.id == currentUserId,
                };
              }).toList();

              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 16),
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
                            child: const Icon(Icons.arrow_back_ios_rounded,
                                color: AppColors.textPrimary, size: 18),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Leaderboard',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Top players of all time',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .slideY(begin: -0.3, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),

                  // Top 3 Podium (if we have at least 1 player)
                  if (leaderboardData.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // 2nd place
                          if (leaderboardData.length > 1)
                            _PodiumCard(
                              data: leaderboardData[1],
                              isCurrentUser: leaderboardData[1]['isCurrentUser'],
                            )
                          else
                            const Expanded(child: SizedBox()),
                            
                          const SizedBox(width: 12),
                          
                          // 1st place (taller)
                          _PodiumCard(
                            data: leaderboardData[0],
                            isFirst: true,
                            isCurrentUser: leaderboardData[0]['isCurrentUser'],
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // 3rd place
                          if (leaderboardData.length > 2)
                            _PodiumCard(
                              data: leaderboardData[2],
                              isCurrentUser: leaderboardData[2]['isCurrentUser'],
                            )
                          else
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    )
                        .animate()
                        .slideY(begin: 0.3, end: 0, duration: 600.ms, delay: 150.ms)
                        .fadeIn(duration: 600.ms, delay: 150.ms),

                  const SizedBox(height: 20),

                  // List for the rest
                  if (leaderboardData.length > 3)
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        itemCount: leaderboardData.length - 3,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final entry = leaderboardData[index + 3];
                          return _LeaderboardRow(
                            entry: entry,
                            isCurrentUser: entry['isCurrentUser'],
                          )
                              .animate(
                                  delay: Duration(milliseconds: 300 + index * 70))
                              .slideX(
                                begin: 0.4,
                                end: 0,
                                duration: 400.ms,
                                curve: Curves.easeOutCubic,
                              )
                              .fadeIn(duration: 400.ms);
                        },
                      ),
                    )
                  else if (leaderboardData.length <= 3 && leaderboardData.isNotEmpty)
                    const Spacer()
                  else
                    const SizedBox(),

                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isFirst;
  final bool isCurrentUser;

  const _PodiumCard({
    required this.data,
    this.isFirst = false,
    required this.isCurrentUser,
  });

  Color get _medalColor {
    final rank = data['rank'] as int;
    if (rank == 1) return AppColors.gold;
    if (rank == 2) return AppColors.silver;
    return AppColors.bronze;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: isFirst ? 170 : 148,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _medalColor.withOpacity(0.18),
              _medalColor.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _medalColor.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _medalColor.withOpacity(0.15),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isFirst)
              Icon(Icons.emoji_events_rounded,
                  color: AppColors.gold, size: 22),
            const SizedBox(height: 6),
            CircleAvatar(
              radius: isFirst ? 30 : 26,
              backgroundColor: _medalColor.withOpacity(0.2),
              child: Text(
                data['avatar'] as String,
                style: GoogleFonts.poppins(
                  fontSize: isFirst ? 16 : 14,
                  fontWeight: FontWeight.w700,
                  color: _medalColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '#${data['rank']}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _medalColor,
              ),
            ),
            Text(
              data['name'] as String,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${data['score']}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isCurrentUser;

  const _LeaderboardRow(
      {required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderColor: isCurrentUser
          ? AppColors.neonBlue.withOpacity(0.6)
          : AppColors.glassBorder,
      gradient: isCurrentUser
          ? const LinearGradient(
              colors: [Color(0x2200C6FF), Color(0x147F00FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : null,
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: Text(
              '#${entry['rank']}',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isCurrentUser
                    ? AppColors.neonBlue
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: isCurrentUser
                ? AppColors.neonBlue.withOpacity(0.2)
                : AppColors.glassWhite,
            child: Text(
              entry['avatar'] as String,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isCurrentUser
                    ? AppColors.neonBlue
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrentUser
                        ? AppColors.neonBlue
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppColors.neonBlue.withOpacity(0.15)
                  : AppColors.glassWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrentUser
                    ? AppColors.neonBlue.withOpacity(0.4)
                    : AppColors.glassBorder,
              ),
            ),
            child: Text(
              '${entry['score']}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isCurrentUser
                    ? AppColors.neonBlue
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
