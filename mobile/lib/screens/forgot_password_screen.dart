import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import '../core/parking_i18n.dart';

enum _ForgotStep { email, otp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  _ForgotStep _step = _ForgotStep.email;

  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String _email = '';

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  void _goToStep(_ForgotStep step) {
    _animController.reset();
    setState(() => _step = step);
    _animController.forward();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleSendEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack(context.t.tr('validEmail'), error: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().forgotPassword(email);
    } catch (_) {}
    if (mounted) {
      _email = email;
      setState(() => _isLoading = false);
      // Always advance — don't reveal whether email exists
      _goToStep(_ForgotStep.otp);
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otp.length < 6) {
      _showSnack(context.t.tr('validOtp'), error: true);
      return;
    }
    _goToStep(_ForgotStep.newPassword);
  }

  Future<void> _handleResetPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.length < 8) {
      _showSnack('Password must be at least 8 characters.', error: true);
      return;
    }
    if (newPass != confirmPass) {
      _showSnack('Passwords do not match.', error: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().resetPassword(
            email: _email,
            otp: _otp,
            newPassword: newPass,
          );
      if (mounted) {
        _showSnack(context.t.tr('passwordResetSuccess'));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Invalid or expired code.', error: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -60,
            right: -80,
            child: _GradientBlob(
              color: AppTheme.primary.withValues(alpha: 0.25),
              size: 280,
            ),
          ),
          Positioned(
            bottom: size.height * 0.2,
            left: -60,
            child: _GradientBlob(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
              size: 220,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                        onPressed: () {
                          if (_step == _ForgotStep.otp) {
                            _goToStep(_ForgotStep.email);
                          } else if (_step == _ForgotStep.newPassword) {
                            _goToStep(_ForgotStep.otp);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Step progress indicator
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: _StepIndicator(currentStep: _step),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: SlideTransition(
                      position: _slideAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildStepContent(isDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    switch (_step) {
      case _ForgotStep.email:
        return _buildEmailStep(isDark);
      case _ForgotStep.otp:
        return _buildOtpStep(isDark);
      case _ForgotStep.newPassword:
        return _buildNewPasswordStep(isDark);
    }
  }

  // ─── Step 1: Email ────────────────────────────────────────
  Widget _buildEmailStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _GlassIconBadge(icon: Icons.mark_email_unread_outlined),
        const SizedBox(height: 24),
        Text(
          context.t.tr('forgotPassword'),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your registered email and we'll send you a reset code.",
          style: TextStyle(
            fontSize: 15,
            color: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        _PremiumTextField(
          controller: _emailController,
          label: context.t.tr('emailLabel'),
          hint: 'you@company.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
          onSubmitted: (_) => _handleSendEmail(),
        ),
        const SizedBox(height: 32),
        _PrimaryButton(
          label: context.t.tr('sendResetCode'),
          icon: Icons.send_rounded,
          isLoading: _isLoading,
          onPressed: _handleSendEmail,
        ),
      ],
    );
  }

  // ─── Step 2: OTP ──────────────────────────────────────────
  Widget _buildOtpStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _GlassIconBadge(icon: Icons.key_rounded),
        const SizedBox(height: 24),
        Text(
          'Enter OTP Code',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${context.t.tr('otpSentToEmail')} Check $_email.',
          style: TextStyle(
            fontSize: 15,
            color: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        // 6-digit OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
            (i) => _OtpBox(
              controller: _otpControllers[i],
              focusNode: _otpFocusNodes[i],
              isDark: isDark,
              onChanged: (val) {
                if (val.isNotEmpty && i < 5) {
                  _otpFocusNodes[i + 1].requestFocus();
                } else if (val.isEmpty && i > 0) {
                  _otpFocusNodes[i - 1].requestFocus();
                }
                setState(() {});
              },
            ),
          ),
        ),
        const SizedBox(height: 32),
        _PrimaryButton(
          label: context.t.tr('verifyCode'),
          icon: Icons.verified_user_rounded,
          isLoading: _isLoading,
          onPressed: _handleVerifyOtp,
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Resend Code'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() => _isLoading = true);
                    try {
                      await context
                          .read<AuthProvider>()
                          .forgotPassword(_email);
                    } catch (_) {}
                    if (mounted) {
                      setState(() => _isLoading = false);
                      _showSnack('A new code has been sent.');
                    }
                  },
          ),
        ),
      ],
    );
  }

  // ─── Step 3: New Password ─────────────────────────────────
  Widget _buildNewPasswordStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _GlassIconBadge(icon: Icons.lock_reset_rounded),
        const SizedBox(height: 24),
        Text(
          'Set New Password',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create a strong password with at least 8 characters.',
          style: TextStyle(
            fontSize: 15,
            color: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        _PremiumTextField(
          controller: _newPasswordController,
          label: context.t.tr('newPasswordLabel'),
          hint: 'At least 8 characters',
          icon: Icons.lock_outline_rounded,
          obscureText: !_showNewPassword,
          isDark: isDark,
          suffixIcon: IconButton(
            icon: Icon(
              _showNewPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _showNewPassword = !_showNewPassword),
          ),
        ),
        const SizedBox(height: 16),
        _PremiumTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Repeat new password',
          icon: Icons.lock_outline_rounded,
          obscureText: !_showConfirmPassword,
          isDark: isDark,
          suffixIcon: IconButton(
            icon: Icon(
              _showConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _showConfirmPassword = !_showConfirmPassword),
          ),
          onSubmitted: (_) => _handleResetPassword(),
        ),
        const SizedBox(height: 32),
        _PrimaryButton(
          label: context.t.tr('updatePassword'),
          icon: Icons.check_circle_outline_rounded,
          isLoading: _isLoading,
          onPressed: _handleResetPassword,
        ),
      ],
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _GradientBlob extends StatelessWidget {
  const _GradientBlob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _GlassIconBadge extends StatelessWidget {
  const _GlassIconBadge({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 32),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final _ForgotStep currentStep;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _ForgotStep.email,
      _ForgotStep.otp,
      _ForgotStep.newPassword
    ];
    final currentIdx = steps.indexOf(currentStep);

    return Row(
      children: steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final isActive = idx == currentIdx;
        final isDone = idx < currentIdx;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isDone || isActive
                    ? AppTheme.primary
                    : AppTheme.primary.withValues(alpha: 0.2),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? AppTheme.accentDark : AppTheme.accentLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      style: TextStyle(
        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? AppTheme.textSecondaryDark.withValues(alpha: 0.4)
              : AppTheme.textSecondaryLight.withValues(alpha: 0.4),
        ),
        labelStyle: TextStyle(
          color:
              isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        ),
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppTheme.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.accentLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
