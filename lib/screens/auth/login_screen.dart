import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../core/app_strings.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() => _isLoading = true);
    
    String? error = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
    // Başarılı ise stream otomatik yönlendirecek
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // ─── LOGO & BRANDING ───
                _buildBranding(isDark),

                const SizedBox(height: AppTheme.space2xl),

                // ─── FORM ALANI ───
                _buildForm(),

                const SizedBox(height: AppTheme.spaceLg),

                // ─── GİRİŞ BUTONU ───
                _buildLoginButton(),

                const SizedBox(height: AppTheme.spaceMd),

                // ─── KAYIT OL LINKİ ───
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                  },
                  child: Text.rich(
                    TextSpan(
                      text: "Hesabın yok mu? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: "Kayıt Ol",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spaceLg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(bool isDark) {
    return Column(
      children: [
        // Gradient yıldız ikonu
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gradientStart.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.star_rounded, size: 44, color: Colors.white),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Text(
          AppStrings.appName,
          style: GoogleFonts.outfit(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Text(
          AppStrings.appTagline,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        // Email alanı
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: AppStrings.email,
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        // Şifre alanı
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: AppStrings.password,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _login,
                  child: const Text(AppStrings.login),
                ),
              ),
      ),
    );
  }
}