import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/sync_service.dart';
import 'screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();

  final _authService = AuthService();
  final _profileService = ProfileService();
  final _syncService = SyncService();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const _primary = Color(0xFF00796B); // Teal shade for Lagmay
  static const _secondary = Color(0xFF4DB6AC); // Lighter teal

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutQuart));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _idNumberCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool hasInternet = await _syncService.hasInternet();
      
      if (_isSignUp) {
        await _authService.signUp(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          name: _nameCtrl.text,
          idNumber: _idNumberCtrl.text,
          section: _sectionCtrl.text,
        );
        if (hasInternet) {
          await _profileService.createProfile(
            name: _nameCtrl.text,
            idNumber: _idNumberCtrl.text,
            section: _sectionCtrl.text,
          );
        }
      } else {
        await _authService.signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
    _animCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF0F4F8),
            ),
          ),
          Positioned(
            top: -size.width * 0.4,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 1.2,
              height: size.width * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _secondary.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.3,
            left: -size.width * 0.3,
            child: Container(
              width: size.width,
              height: size.width,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primary.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Form Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      // Glassmorphism effect
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.school_rounded, size: 48, color: _primary),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _isSignUp ? 'Create Account' : 'Welcome',
                                    style: const TextStyle(
                                      color: Color(0xFF263238),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isSignUp 
                                        ? 'Join us and manage your academic life offline & online.' 
                                        : 'Please sign in to continue your journey.',
                                    style: const TextStyle(color: Color(0xFF78909C), fontSize: 14, height: 1.4),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 36),
                                  
                                  _buildTextField(
                                    controller: _emailCtrl,
                                    hint: 'Email Address',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _passwordCtrl,
                                    hint: 'Password',
                                    icon: Icons.lock_outline_rounded,
                                    obscure: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF78909C)),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),

                                  if (_isSignUp) ...[
                                    const SizedBox(height: 16),
                                    _buildTextField(controller: _nameCtrl, hint: 'Full Name', icon: Icons.person_outline),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(child: _buildTextField(controller: _idNumberCtrl, hint: 'ID Number', icon: Icons.badge_outlined)),
                                        const SizedBox(width: 16),
                                        Expanded(child: _buildTextField(controller: _sectionCtrl, hint: 'Section', icon: Icons.class_outlined)),
                                      ],
                                    ),
                                  ],

                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53935).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 36),
                                  
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 8,
                                        shadowColor: _primary.withValues(alpha: 0.4),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                          : Text(
                                              _isSignUp ? 'Create Account' : 'Log In', 
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                                            ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                                        style: const TextStyle(color: Color(0xFF78909C)),
                                      ),
                                      GestureDetector(
                                        onTap: _toggleMode,
                                        child: Text(
                                          _isSignUp ? 'Log In' : 'Sign Up',
                                          style: const TextStyle(color: _primary, fontWeight: FontWeight.bold),
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
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF263238), fontWeight: FontWeight.w500),
      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFF78909C).withValues(alpha: 0.8), fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, color: _primary.withValues(alpha: 0.7)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE53935), width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE53935), width: 2)),
      ),
    );
  }
}
