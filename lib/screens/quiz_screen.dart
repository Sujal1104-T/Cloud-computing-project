import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../constants/app_colors.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import 'result_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class QuizScreen extends StatefulWidget {
  final String category;
  final String categoryId;
  const QuizScreen({super.key, required this.category, required this.categoryId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  int? _selectedOption;
  int _score = 0;
  late AnimationController _timerController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _answered = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _nextQuestion();
      });

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      QuerySnapshot snapshot;
      
      if (widget.categoryId == 'mixed') {
        snapshot = await FirebaseFirestore.instance
            .collectionGroup('questions')
            .limit(10)
            .get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(widget.categoryId)
            .collection('questions')
            .limit(10)
            .get();
      }
      
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _questions = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final List<String> options = List<String>.from(data['options'] ?? []);
            final String correctAnswer = data['answer'] ?? '';
            // Find the index of the correct answer string in the options list
            int correctIndex = options.indexOf(correctAnswer);
            if (correctIndex == -1) correctIndex = 0; // Fallback

            return {
              'question': data['question'] ?? 'No question text',
              'options': options,
              'correct': correctIndex,
            };
          }).toList();
          _isLoading = false;
        });
        _timerController.forward();
        _slideController.forward();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _selectOption(int index) {
    if (_answered || _questions.isEmpty) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == _questions[_currentIndex]['correct']) _score++;
    });
    Future.delayed(const Duration(milliseconds: 900), _nextQuestion);
  }

  void _nextQuestion() {
    if (!mounted || _questions.isEmpty) return;
    if (_currentIndex < _questions.length - 1) {
      _slideController.reset();
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
      _timerController.reset();
      _timerController.forward();
      _slideController.forward();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => ResultScreen(
            score: _score,
            total: _questions.length,
            category: widget.category,
          ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Color _getOptionColor(int index) {
    if (_selectedOption == null) return AppColors.glassWhite;
    final correct = _questions[_currentIndex]['correct'] as int;
    if (index == correct) return AppColors.success.withOpacity(0.25);
    if (index == _selectedOption && index != correct) {
      return AppColors.error.withOpacity(0.25);
    }
    return AppColors.glassWhite;
  }

  Color _getOptionBorderColor(int index) {
    if (_selectedOption == null) return AppColors.glassBorder;
    final correct = _questions[_currentIndex]['correct'] as int;
    if (index == correct) return AppColors.success;
    if (index == _selectedOption && index != correct) return AppColors.error;
    return AppColors.glassBorder;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: AnimatedBackground(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.neonBlue),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: AnimatedBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No questions available!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                GlowButton(
                  text: 'Go Back',
                  onPressed: () => Navigator.of(context).pop(),
                  width: 150,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final timeLeft = (1 - _timerController.value);
    final secondsLeft = (timeLeft * 30).ceil();

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Text(
                      widget.category,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    // Timer
                    CircularPercentIndicator(
                      radius: 26,
                      lineWidth: 4,
                      percent: timeLeft,
                      center: Text(
                        '$secondsLeft',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: timeLeft > 0.3
                              ? AppColors.neonBlue
                              : AppColors.error,
                        ),
                      ),
                      progressColor: timeLeft > 0.3
                          ? AppColors.neonBlue
                          : AppColors.error,
                      backgroundColor: AppColors.glassWhite,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _questions.length,
                    backgroundColor: AppColors.glassWhite,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.neonBlue),
                    minHeight: 6,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1} of ${_questions.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Score: $_score',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.neonBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Question Card - slide in animation
                SlideTransition(
                  position: _slideAnimation,
                  child: GlassCard(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Q${_currentIndex + 1}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          question['question'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Options
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        (question['options'] as List<String>).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final opt = (question['options'] as List<String>)[index];
                      return _OptionButton(
                        label: opt,
                        index: index,
                        onTap: () => _selectOption(index),
                        bgColor: _getOptionColor(index),
                        borderColor: _getOptionBorderColor(index),
                        isSelected: _selectedOption == index,
                        isCorrect: _answered &&
                            index ==
                                _questions[_currentIndex]['correct'] as int,
                      )
                          .animate(delay: Duration(milliseconds: index * 80))
                          .slideX(
                            begin: 0.3,
                            end: 0,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          )
                          .fadeIn(duration: 400.ms);
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Next button
                GlowButton(
                  text: _currentIndex < _questions.length - 1
                      ? 'Next Question'
                      : 'See Results',
                  width: double.infinity,
                  height: 56,
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final int index;
  final VoidCallback onTap;
  final Color bgColor;
  final Color borderColor;
  final bool isSelected;
  final bool isCorrect;

  const _OptionButton({
    required this.label,
    required this.index,
    required this.onTap,
    required this.bgColor,
    required this.borderColor,
    required this.isSelected,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['A', 'B', 'C', 'D'];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isSelected || isCorrect
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor.withOpacity(0.6)),
              ),
              child: Center(
                child: Text(
                  labels[index],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected || isCorrect
                        ? borderColor
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isCorrect)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 22)
            else if (isSelected && !isCorrect)
              const Icon(Icons.cancel_rounded,
                  color: AppColors.error, size: 22),
          ],
        ),
      ),
    );
  }
}
