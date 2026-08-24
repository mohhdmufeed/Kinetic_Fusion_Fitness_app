import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../shared/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;

  final FocusNode _userFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();
  final FocusNode _pass2Focus = FocusNode();

  bool _userFocused = false;
  bool _emailFocused = false;
  bool _nameFocused = false;
  bool _passFocused = false;
  bool _pass2Focused = false;

  @override
  void initState() {
    super.initState();
    _userFocus.addListener(() => setState(() => _userFocused = _userFocus.hasFocus));
    _emailFocus.addListener(() => setState(() => _emailFocused = _emailFocus.hasFocus));
    _nameFocus.addListener(() => setState(() => _nameFocused = _nameFocus.hasFocus));
    _passFocus.addListener(() => setState(() => _passFocused = _passFocus.hasFocus));
    _pass2Focus.addListener(() => setState(() => _pass2Focused = _pass2Focus.hasFocus));
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    _userFocus.dispose();
    _emailFocus.dispose();
    _nameFocus.dispose();
    _passFocus.dispose();
    _pass2Focus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final username = _userCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final displayName = _nameCtrl.text.trim();
    final password = _passCtrl.text;

    final result = await ref.read(authServiceProvider).register(
          username,
          password,
          email,
          displayName: displayName.isNotEmpty ? displayName : username,
        );

    if (!mounted) return;

    if (result['success'] == true) {
      ref.invalidate(isLoggedInProvider);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF161B26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Text('Verify Your Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We have registered account "$username". A time-limited signed verification link has been dispatched to $email.',
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Text(
                'Please verify your email address to unlock full cloud sync and data endpoints.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/onboarding');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF0B0E14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Continue to Setup →', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = result['error'] ?? 'Registration failed. Please check requirements.';
        _loading = false;
      });
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onSubmitted,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused ? const Color(0xFF38BDF8) : const Color(0xFF334155),
          width: isFocused ? 2.0 : 1.5,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: const Color(0xFF38BDF8),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 12),
            child: Icon(
              prefixIcon,
              color: isFocused ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 22),
          suffixIcon: isPassword
              ? IconButton(
                  splashRadius: 20,
                  icon: Icon(
                    obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: isFocused ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                    size: 22,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0E14),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/hex_dumbbells_floor.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0B0E14).withOpacity(0.85),
                      const Color(0xFF0B0E14).withOpacity(0.98),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Center(
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF38BDF8).withOpacity(0.12),
                              border: Border.all(
                                color: const Color(0xFF38BDF8).withOpacity(0.35),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withOpacity(0.2),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/kinetic_precision_dumbbell.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.fitness_center_rounded,
                                    size: 36,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Join Kinetic Precision for secure fitness intelligence',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.error.withOpacity(0.5)),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildField(
                                controller: _userCtrl,
                                focusNode: _userFocus,
                                isFocused: _userFocused,
                                hintText: 'Username',
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (v) => v == null || v.trim().length < 3
                                    ? 'Minimum 3 characters'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                controller: _nameCtrl,
                                focusNode: _nameFocus,
                                isFocused: _nameFocused,
                                hintText: 'Display Name (e.g. Alex Rivera)',
                                prefixIcon: Icons.badge_outlined,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Please enter your display name'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                controller: _emailCtrl,
                                focusNode: _emailFocus,
                                isFocused: _emailFocused,
                                hintText: 'Email Address',
                                prefixIcon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Please enter email';
                                  if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                controller: _passCtrl,
                                focusNode: _passFocus,
                                isFocused: _passFocused,
                                hintText: 'Password (min. 10 chars)',
                                prefixIcon: Icons.lock_outline_rounded,
                                isPassword: true,
                                obscure: _obscure1,
                                onToggleObscure: () => setState(() => _obscure1 = !_obscure1),
                                validator: (v) => v == null || v.length < 10
                                    ? 'Minimum 10 characters required'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                controller: _pass2Ctrl,
                                focusNode: _pass2Focus,
                                isFocused: _pass2Focused,
                                hintText: 'Confirm Password',
                                prefixIcon: Icons.lock_clock_outlined,
                                isPassword: true,
                                obscure: _obscure2,
                                onToggleObscure: () => setState(() => _obscure2 = !_obscure2),
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _register(),
                                validator: (v) => v != _passCtrl.text
                                    ? 'Passwords do not match'
                                    : null,
                              ),
                              const SizedBox(height: 28),

                              // Submit Button
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF38BDF8),
                                    foregroundColor: const Color(0xFF0B0E14),
                                    disabledBackgroundColor: const Color(0xFF38BDF8).withOpacity(0.5),
                                    elevation: 4,
                                    shadowColor: const Color(0xFF38BDF8).withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF0B0E14),
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Footer link to Login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
