import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────────
  bool _isLogin = true; // true = Log In, false = Sign Up
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  // ── Theme Constants ───────────────────────────────────────────────────────
  static const _bg = Color(0xFF0A0E27);
  static const _cyan = Color(0xFF00D9FF);
  static const _cyanDark = Color(0xFF0099BB);
  static const _panelBg = Color(0xFF0F1535);
  static const _panelBorder = Color(0xFF1E2D5A);
  static const _errorRed = Color(0xFFFF4C6A);

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Auth Logic ────────────────────────────────────────────────────────────

  Future<void> _onEngageThrusters() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final auth = Supabase.instance.client.auth;

    try {
      if (_isLogin) {
        await auth.signInWithPassword(email: email, password: password);
      } else {
        final response = await auth.signUp(email: email, password: password);
        if (response.user != null && response.session == null && mounted) {
          _showSnack(
            '✅ Confirmation email sent — check your inbox, Pilot.',
            _cyan,
          );
          setState(() {
            _isLogin = true;
            _isLoading = false;
          });
          return;
        }
      }
    } on AuthException catch (e) {
      if (mounted) _showSnack('⚠ ${e.message}', _errorRed);
    } catch (e) {
      if (mounted) _showSnack('⚠ Connection failure: $e', _errorRed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.roboto(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: color.withAlpha(230),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            // Background star field effect
            _buildStarField(),
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildStarField() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (_, __) => CustomPaint(
        painter: _StarFieldPainter(opacity: _glowAnimation.value),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Glowing rocket icon
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (_, __) => Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _cyan.withAlpha((_glowAnimation.value * 60).toInt()),
                  _bg.withAlpha(0),
                ],
              ),
              border: Border.all(
                color: _cyan.withAlpha((_glowAnimation.value * 180).toInt()),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: _cyan, size: 42),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'STARDUST',
          style: GoogleFonts.orbitron(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: _cyan,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'FINANCE COMMAND',
          style: GoogleFonts.orbitron(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: _cyan.withAlpha(150),
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 10),
        // Divider with glow
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (_, __) => Container(
            height: 1,
            width: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _cyan.withAlpha((_glowAnimation.value * 200).toInt()),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _panelBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: _cyan.withAlpha(15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Mode Toggle ──
            _buildModeToggle(),
            const SizedBox(height: 24),

            // ── Mode Label ──
            Text(
              _isLogin ? 'PILOT AUTHENTICATION' : 'RECRUIT REGISTRATION',
              style: GoogleFonts.orbitron(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _cyan,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isLogin
                  ? 'Enter your credentials to access the command bridge.'
                  : 'Register your pilot profile to begin your mission.',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.white38,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ── Email Field ──
            _buildLabel('COMM FREQUENCY (EMAIL)'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _emailController,
              hint: 'pilot@stardust.io',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Password Field ──
            _buildLabel('SECURITY CODE (PASSWORD)'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _passwordController,
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white38,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password required';
                if (!_isLogin && v.length < 6) {
                  return 'Minimum 6 characters required';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            // ── Engage Thrusters Button ──
            _buildEngageButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _panelBorder),
      ),
      child: Row(
        children: [
          _toggleOption(
            label: 'PILOT AUTH',
            isSelected: _isLogin,
            onTap: () => setState(() => _isLogin = true),
            isLeft: true,
          ),
          _toggleOption(
            label: 'RECRUIT REG',
            isSelected: !_isLogin,
            onTap: () => setState(() => _isLogin = false),
            isLeft: false,
          ),
        ],
      ),
    );
  }

  Widget _toggleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isLeft,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? _cyan.withAlpha(30) : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? const Radius.circular(9) : Radius.zero,
              right: !isLeft ? const Radius.circular(9) : Radius.zero,
            ),
            border: isSelected
                ? Border.all(color: _cyan.withAlpha(120), width: 1)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isSelected ? _cyan : Colors.white38,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: Colors.white38,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.roboto(color: Colors.white, fontSize: 14),
      cursorColor: _cyan,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.roboto(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF0A0E27),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _cyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _errorRed),
        ),
        errorStyle: GoogleFonts.roboto(color: _errorRed, fontSize: 11),
      ),
    );
  }

  Widget _buildEngageButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _cyan.withAlpha((_glowAnimation.value * 80).toInt()),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _onEngageThrusters,
          style: ElevatedButton.styleFrom(
            backgroundColor: _cyan,
            disabledBackgroundColor: _cyanDark.withAlpha(100),
            foregroundColor: const Color(0xFF0A0E27),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF0A0E27),
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'ENGAGE THRUSTERS',
                      style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Star Field Painter ────────────────────────────────────────────────────────

class _StarFieldPainter extends CustomPainter {
  final double opacity;
  _StarFieldPainter({required this.opacity});

  // Fixed star positions (deterministic, no randomness at paint time)
  static const List<_Star> _stars = [
    _Star(0.05, 0.10, 1.2), _Star(0.18, 0.25, 0.8), _Star(0.32, 0.08, 1.5),
    _Star(0.50, 0.15, 1.0), _Star(0.68, 0.05, 1.3), _Star(0.82, 0.20, 0.9),
    _Star(0.92, 0.12, 1.1), _Star(0.10, 0.40, 0.7), _Star(0.25, 0.55, 1.4),
    _Star(0.45, 0.38, 0.6), _Star(0.60, 0.50, 1.2), _Star(0.75, 0.42, 0.8),
    _Star(0.88, 0.60, 1.0), _Star(0.15, 0.70, 1.3), _Star(0.35, 0.80, 0.9),
    _Star(0.55, 0.72, 1.5), _Star(0.70, 0.88, 0.7), _Star(0.90, 0.78, 1.1),
    _Star(0.03, 0.85, 0.8), _Star(0.48, 0.92, 1.2), _Star(0.22, 0.65, 1.0),
    _Star(0.78, 0.30, 0.6), _Star(0.40, 0.45, 1.4), _Star(0.95, 0.50, 0.9),
    _Star(0.12, 0.92, 1.3),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in _stars) {
      paint.color = Colors.white.withAlpha(
        (opacity * star.brightness * 120).toInt().clamp(0, 255),
      );
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter old) => old.opacity != opacity;
}

class _Star {
  final double x, y, brightness;
  double get radius => brightness * 0.8 + 0.4;
  const _Star(this.x, this.y, this.brightness);
}
