import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../core/app_strings.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      String? error = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      } else {
        // Başarılı olursa zaten main.dart'taki stream bizi Home'a atacak
        if (!mounted) return;
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
            child: Column(
              children: [
                const SizedBox(height: AppTheme.spaceLg),

                // ─── GERİ BUTONU + BAŞLIK ───
                _buildHeader(),

                const SizedBox(height: AppTheme.spaceXl),

                // ─── KAYIT FORMU ───
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // İsim alanı
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.nameSurname,
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) => val!.isEmpty ? "İsim boş olamaz" : null,
                      ),
                      const SizedBox(height: AppTheme.spaceMd),

                      // Email alanı
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: AppStrings.email,
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (val) => val!.contains('@') ? null : "Geçerli bir e-posta girin",
                      ),
                      const SizedBox(height: AppTheme.spaceMd),

                      // Şifre alanı
                      TextFormField(
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
                        validator: (val) => val!.length < 6 ? "Şifre en az 6 karakter olmalı" : null,
                      ),
                      const SizedBox(height: AppTheme.spaceLg),

                      // Kayıt Butonu
                      _buildRegisterButton(),

                      const SizedBox(height: AppTheme.spaceMd),

                      // Giriş yap linki
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text.rich(
                          TextSpan(
                            text: "Zaten hesabın var mı? ",
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: "Giriş Yap",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Geri butonu
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        // Başlık
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gradientStart.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.person_add_rounded, size: 32, color: Colors.white),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Text(
          AppStrings.register,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Text(
          "Hemen hesap oluştur ve puanlamaya başla!",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
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
                  onPressed: _register,
                  child: const Text(AppStrings.register),
                ),
              ),
      ),
    );
  }
}