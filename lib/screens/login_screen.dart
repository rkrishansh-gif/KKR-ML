// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isRegisterMode = !_isRegisterMode);
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app.AuthProvider>(context);
    final screenH = MediaQuery.of(context).size.height;
    final topPadding = (screenH * 0.07).clamp(32.0, 72.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: topPadding),
              _buildHeader(screenH),
              SizedBox(height: (screenH * 0.05).clamp(24.0, 48.0)),
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _buildMainSection(authProvider),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(double screenH) {
    final logoSize = (screenH * 0.11).clamp(70.0, 96.0);
    final iconSize = logoSize * 0.50;
    final titleSize = screenH < 680 ? 17.0 : 20.0;

    return Column(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.35),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child:
              Icon(Icons.school_rounded, size: iconSize, color: Colors.white),
        ),
        const SizedBox(height: 18),
        Text(
          'KKR ML CLASSES',
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Learn. Grow. Succeed.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontFamily: 'Poppins',
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ── Main Section ─────────────────────────────────────────────────────────────
  Widget _buildMainSection(app.AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card ──
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isRegisterMode ? 'Create Account ✨' : 'Welcome Back 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isRegisterMode
                    ? 'Register karo aur seekhna shuru karo'
                    : 'Login karo apne account mein',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 22),

              // Username — sirf register mein
              if (_isRegisterMode) ...[
                _buildInputField(
                  controller: _usernameController,
                  hint: 'Username',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
              ],

              // Email
              _buildInputField(
                controller: _emailController,
                hint: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // Password
              _buildInputField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),

              const SizedBox(height: 20),

              // Login / Register button
              _primaryBtn(
                label: _isRegisterMode ? 'Register' : 'Login',
                isLoading: authProvider.isLoading,
                onTap: () => _isRegisterMode
                    ? _handleRegister(authProvider)
                    : _handleLogin(authProvider),
              ),

              const SizedBox(height: 16),

              // Toggle login/register
              Center(
                child: GestureDetector(
                  onTap: _toggleMode,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 13),
                      children: [
                        TextSpan(
                          text: _isRegisterMode
                              ? 'Pehle se account hai? '
                              : 'Naya account banana hai? ',
                          style:
                              const TextStyle(color: Colors.white38),
                        ),
                        TextSpan(
                          text: _isRegisterMode ? 'Login' : 'Register',
                          style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // OR divider
        Row(
          children: [
            Expanded(
                child:
                    Divider(color: Colors.white.withOpacity(0.08))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.24),
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
                child:
                    Divider(color: Colors.white.withOpacity(0.08))),
          ],
        ),

        const SizedBox(height: 22),

        // Google button
        GestureDetector(
          onTap: () async {
            final result = await authProvider.loginWithGoogle();
            if (!mounted) return;

            if (result == null) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (result == 'setup_name') {
              Navigator.pushReplacementNamed(context, '/setup-name');
            } else if (result != 'cancelled') {
              _showError(result);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E30),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.g_mobiledata_rounded,
                    color: Colors.white70, size: 26),
                SizedBox(width: 10),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        const Center(
          child: Text(
            'By continuing, you agree to our Terms & Privacy Policy',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white24,
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  // ── Input Field ──────────────────────────────────────────────────────────────
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: Colors.white24, fontFamily: 'Poppins'),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white38,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        ),
      ),
    );
  }

  // ── Primary Button ───────────────────────────────────────────────────────────
  Widget _primaryBtn({
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Logic ────────────────────────────────────────────────────────────────────
  Future<void> _handleLogin(app.AuthProvider authProvider) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Email aur password dono bharo');
      return;
    }

    final result = await authProvider.loginWithEmail(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (result == null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showError(result);
    }
  }

  Future<void> _handleRegister(app.AuthProvider authProvider) async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Saare fields bharo');
      return;
    }

    if (password.length < 6) {
      _showError('Password kam se kam 6 characters ka hona chahiye');
      return;
    }

    final result = await authProvider.registerWithEmail(
      username: username,
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (result == null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showError(result);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}