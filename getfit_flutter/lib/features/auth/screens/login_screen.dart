import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';

class HexagonPainter extends CustomPainter {
  final Color color;
  HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  bool _advancedOpen = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await ref
        .read(authServiceProvider)
        .login(_usernameCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      ref.invalidate(isLoggedInProvider);
      context.go('/dashboard');
    } else {
      setState(() {
        _error = 'Invalid username or password';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background split: Navy top & White bottom
          Column(
            children: [
              Container(
                height: size.height * 0.48,
                width: double.infinity,
                color: navyColor,
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF9FAFB),
                ),
              ),
            ],
          ),

          // Scrollable Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      // Hexagon Logo
                      CustomPaint(
                        size: const Size(82, 92),
                        painter: HexagonPainter(color: Colors.white),
                        child: const SizedBox(
                          width: 82,
                          height: 92,
                          child: Center(
                            child: Icon(
                              Icons.fitness_center_rounded,
                              size: 40,
                              color: navyColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'GetFit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Floating Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_error != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8D7DA),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                        color: Color(0xFF721C24), fontSize: 13),
                                  ),
                                ),
                              ],

                              // Username field
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.account_circle,
                                    color: Color(0xFF2E4057),
                                    size: 26,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Username',
                                          style: TextStyle(
                                            color: Color(0xFF26496C),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextFormField(
                                          controller: _usernameCtrl,
                                          style: const TextStyle(
                                            color: Color(0xFF212529),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.only(top: 4, bottom: 6),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: navyColor, width: 1.5),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: navyColor, width: 1.5),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: navyColor, width: 2),
                                            ),
                                            hintText: 'Enter username',
                                            hintStyle: TextStyle(
                                                color: Colors.grey, fontSize: 14),
                                          ),
                                          validator: (v) => v == null || v.isEmpty
                                              ? 'Please enter username'
                                              : null,
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Password field
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.password_rounded,
                                    color: Color(0xFF2E4057),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _passwordCtrl,
                                      obscureText: _obscure,
                                      style: const TextStyle(
                                        color: Color(0xFF212529),
                                        fontSize: 15,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(vertical: 8),
                                        hintText: 'Password',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF495057),
                                          fontSize: 14,
                                        ),
                                        border: const UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xFFCED4DA)),
                                        ),
                                        enabledBorder: const UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xFFCED4DA)),
                                        ),
                                        focusedBorder: const UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: navyColor, width: 1.5),
                                        ),
                                        suffixIcon: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 20,
                                            color: const Color(0xFF2E4057),
                                          ),
                                          onPressed: () => setState(
                                              () => _obscure = !_obscure),
                                        ),
                                      ),
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'Please enter password'
                                          : null,
                                      onFieldSubmitted: (_) => _login(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Other sign-in options
                              Center(
                                child: InkWell(
                                  onTap: () {},
                                  child: const Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.open_in_new_rounded,
                                            size: 14,
                                            color: Color(0xFF1E3A5F),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Other sign-in options',
                                            style: TextStyle(
                                              color: Color(0xFF1E3A5F),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Social login, passkey, SSO',
                                        style: TextStyle(
                                          color: Color(0xFF6C757D),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),

                              // Log in Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: _loading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                            color: navyColor),
                                      )
                                    : ElevatedButton(
                                        onPressed: _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: navyColor,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Text(
                                          'Log in',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 18),

                              // Register Link
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'New to GetFit? ',
                                      style: TextStyle(
                                        color: Color(0xFF495057),
                                        fontSize: 12,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => context.go('/register'),
                                      child: const Text(
                                        'Register',
                                        style: TextStyle(
                                          color: navyColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Advanced button
                              Center(
                                child: InkWell(
                                  onTap: () => setState(
                                      () => _advancedOpen = !_advancedOpen),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'ADVANCED',
                                        style: TextStyle(
                                          color: Color(0xFF6C757D),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _advancedOpen
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        size: 14,
                                        color: const Color(0xFF6C757D),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_advancedOpen) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Server: https://apk--production.up.railway.app',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6C757D),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
