import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_colors.dart';
import '../widgets/animated_background.dart';
import '../widgets/glow_button.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLogin = true;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _isLogin = _tabController.index == 0);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleAuth() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    if (!_isLogin && name.isEmpty) {
      _showError('Please enter your name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Login
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // Sign Up
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Update display name and create user document
        await credential.user?.updateDisplayName(name);
        await _firestore.collection('users').doc(credential.user?.uid).set({
          'name': name,
          'email': email,
          'total_score': 0,
          'quizzes_taken': 0,
          'rank': 'Newbie',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) _navigateToHome();
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth Error: ${e.code} - ${e.message}');
      _showError(e.message ?? 'Auth Error: ${e.code}');
    } catch (e) {
      debugPrint('General Error: $e');
      _showError('Unexpected error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
      
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: null, // accessToken is handled differently in 7.x
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Create user doc if it doesn't exist
      final userDoc = await _firestore.collection('users').doc(userCredential.user?.uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'name': userCredential.user?.displayName ?? 'User',
          'email': userCredential.user?.email ?? '',
          'total_score': 0,
          'quizzes_taken': 0,
          'rank': 'Newbie',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) _navigateToHome();
    } catch (e) {
      _showError('Google Sign-In failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ── Logo & Branding ─────────────────────────────────────
                  _LogoBrand()
                      .animate()
                      .fadeIn(duration: 700.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        duration: 700.ms,
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: 32),

                  // ── Tab Switcher ────────────────────────────────────────
                  _TabSwitcher(
                    controller: _tabController,
                    isLogin: _isLogin,
                  )
                      .animate()
                      .slideY(begin: 0.3, end: 0, duration: 600.ms, delay: 200.ms)
                      .fadeIn(duration: 600.ms, delay: 200.ms),

                  const SizedBox(height: 24),

                  // ── Form Card ───────────────────────────────────────────
                  _FormCard(
                    tabController: _tabController,
                    isLogin: _isLogin,
                    emailCtrl: _emailCtrl,
                    passwordCtrl: _passwordCtrl,
                    nameCtrl: _nameCtrl,
                    obscurePassword: _obscurePassword,
                    onToggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onContinue: _handleAuth,
                    isLoading: _isLoading,
                  )
                      .animate()
                      .slideY(begin: 0.4, end: 0, duration: 700.ms, delay: 300.ms)
                      .fadeIn(duration: 700.ms, delay: 300.ms),

                  const SizedBox(height: 28),

                  // ── Social Login ────────────────────────────────────────
                  _SocialSection(
                    onGoogleSignIn: _handleGoogleSignIn,
                    onGithubSignIn: () => _showError('GitHub login coming soon!'),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 500.ms),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo & Branding
// ─────────────────────────────────────────────────────────────────────────────
class _LogoBrand extends StatefulWidget {
  @override
  State<_LogoBrand> createState() => _LogoBrandState();
}

class _LogoBrandState extends State<_LogoBrand>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 12, end: 28).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glow,
          builder: (_, child) => Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonBlue.withValues(alpha: 0.5),
                  blurRadius: _glow.value,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppColors.deepPurple.withValues(alpha: 0.3),
                  blurRadius: _glow.value * 1.5,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: child,
          ),
          child: const Icon(
            Icons.quiz_rounded,
            color: Colors.white,
            size: 44,
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          child: Text(
            'QuizMaster',
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Test your knowledge, challenge the world',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Switcher
// ─────────────────────────────────────────────────────────────────────────────
class _TabSwitcher extends StatelessWidget {
  final TabController controller;
  final bool isLogin;

  const _TabSwitcher({required this.controller, required this.isLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonBlue.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        unselectedLabelColor: AppColors.textSecondary,
        labelColor: Colors.white,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Login'),
          Tab(text: 'Sign Up'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form Card (single card, no fixed height)
// ─────────────────────────────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  final TabController tabController;
  final bool isLogin;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController nameCtrl;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onContinue;
  final bool isLoading;

  const _FormCard({
    required this.tabController,
    required this.isLogin,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.nameCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onContinue,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.glassBorder, width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonBlue.withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: _BackdropBlurCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(isLogin ? -0.15 : 0.15, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: anim, curve: Curves.easeOutCubic)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: isLogin
                  ? _LoginFormBody(
                      key: const ValueKey('login'),
                      emailCtrl: emailCtrl,
                      passwordCtrl: passwordCtrl,
                      obscurePassword: obscurePassword,
                      onToggleObscure: onToggleObscure,
                      onContinue: onContinue,
                      isLoading: isLoading,
                    )
                  : _SignUpFormBody(
                      key: const ValueKey('signup'),
                      nameCtrl: nameCtrl,
                      emailCtrl: emailCtrl,
                      passwordCtrl: passwordCtrl,
                      obscurePassword: obscurePassword,
                      onToggleObscure: onToggleObscure,
                      onContinue: onContinue,
                      isLoading: isLoading,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackdropBlurCard extends StatelessWidget {
  final Widget child;
  const _BackdropBlurCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login Form Body
// ─────────────────────────────────────────────────────────────────────────────
class _LoginFormBody extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onContinue;
  final bool isLoading;

  const _LoginFormBody({
    super.key,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onContinue,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome back 👋',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in to continue your quiz journey',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        _GlowTextField(
          controller: emailCtrl,
          hint: 'Email address',
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _GlowTextField(
          controller: passwordCtrl,
          hint: 'Enter your password',
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscureText: obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressed: onToggleObscure,
          ),
        ),
        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Forgot password?',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.neonBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),

        GlowButton(
          text: isLoading ? 'Signing In...' : 'Sign In',
          width: double.infinity,
          height: 56,
          onPressed: isLoading ? () {} : onContinue,
          gradient: AppColors.primaryGradient,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign Up Form Body
// ─────────────────────────────────────────────────────────────────────────────
class _SignUpFormBody extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onContinue;
  final bool isLoading;

  const _SignUpFormBody({
    super.key,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onContinue,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Join QuizMaster 🚀',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Create your account to start competing',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        _GlowTextField(
          controller: nameCtrl,
          hint: 'Your full name',
          label: 'Full Name',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 16),
        _GlowTextField(
          controller: emailCtrl,
          hint: 'Email address',
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _GlowTextField(
          controller: passwordCtrl,
          hint: 'Create a strong password',
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscureText: obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressed: onToggleObscure,
          ),
        ),
        const SizedBox(height: 12),

        // Password strength hint
        Row(
          children: [
            ...[0.9, 0.6, 0.2].map(
              (s) => Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: s == 0.9
                        ? AppColors.primaryGradient
                        : null,
                    color: s < 0.9
                        ? AppColors.glassBorder
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Strength',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        GlowButton(
          text: isLoading ? 'Creating Account...' : 'Create Account',
          width: double.infinity,
          height: 56,
          onPressed: isLoading ? () {} : onContinue,
          gradient: AppColors.primaryGradient,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glow Text Field
// ─────────────────────────────────────────────────────────────────────────────
class _GlowTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _GlowTextField({
    required this.controller,
    required this.hint,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  State<_GlowTextField> createState() => _GlowTextFieldState();
}

class _GlowTextFieldState extends State<_GlowTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isFocused ? AppColors.neonBlue : AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isFocused
                    ? AppColors.neonBlue
                    : AppColors.glassBorder,
                width: _isFocused ? 1.5 : 1.0,
              ),
              color: _isFocused
                  ? AppColors.neonBlue.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.04),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.neonBlue.withValues(alpha: 0.2),
                        blurRadius: 14,
                        spreadRadius: 0,
                      ),
                    ]
                  : [],
            ),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(10),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isFocused
                        ? AppColors.neonBlue.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    color:
                        _isFocused ? AppColors.neonBlue : AppColors.textMuted,
                    size: 18,
                  ),
                ),
                suffixIcon: widget.suffixIcon,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social Section
// ─────────────────────────────────────────────────────────────────────────────
class _SocialSection extends StatelessWidget {
  final VoidCallback onGoogleSignIn;
  final VoidCallback onGithubSignIn;
  
  const _SocialSection({
    required this.onGoogleSignIn,
    required this.onGithubSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.glassBorder,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'or sign in with',
                style: GoogleFonts.poppins(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.glassBorder,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Google',
                onTap: onGoogleSignIn,
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA4335), Color(0xFFFBBC05)],
                ),
                child: _GoogleIcon(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _SocialButton(
                label: 'GitHub',
                onTap: onGithubSignIn,
                gradient: const LinearGradient(
                  colors: [Color(0xFF333333), Color(0xFF666666)],
                ),
                child: const Icon(Icons.code_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw 4 color segments
    final colors = [
      const Color(0xFFEA4335),
      const Color(0xFFFBBC05),
      const Color(0xFF34A853),
      const Color(0xFF4285F4),
    ];
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        (i * math.pi / 2) - math.pi / 4,
        math.pi / 2,
        true,
        paint,
      );
    }

    // Center hole
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paint);

    // G letter bar
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - radius * 0.18,
          radius * 0.88, radius * 0.36),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SocialButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final LinearGradient gradient;
  final Widget child;

  const _SocialButton({
    required this.label,
    required this.onTap,
    required this.gradient,
    required this.child,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder, width: 1),
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.child,
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
