import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../services/auth_service.dart';

/// E-posta doğrulama ekranı
/// Kayıt sonrası kullanıcıya doğrulama e-postasının gönderildiğini bildirir.
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _resending = false;
  bool _resent = false;

  void _resendEmail() async {
    setState(() { _resending = true; _resent = false; });
    try {
      final authService = AuthService();
      final error = await authService.resendVerificationEmail(widget.email);
      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppTheme.danger));
        } else {
          setState(() => _resent = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doğrulama e-postası tekrar gönderildi ✓'), backgroundColor: Colors.green),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // İkon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gradientStart.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.mark_email_read_rounded, size: 44, color: Colors.white),
              ),
              const SizedBox(height: AppTheme.spaceLg),

              // Başlık
              Text(
                'E-postanı Doğrula',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),

              // Açıklama
              Text(
                'Hesabını aktifleştirmek için e-posta adresine gönderilen doğrulama linkine tıkla.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),

              // E-posta adresi badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.email_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      widget.email,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceXl),

              // Yeniden gönder butonu
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _resending ? null : _resendEmail,
                  icon: _resending
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary))
                      : Icon(_resent ? Icons.check_rounded : Icons.refresh_rounded),
                  label: Text(_resent ? 'Tekrar Gönderildi' : 'Tekrar Gönder'),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),

              // Giriş yap butonu
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Giriş ekranına dön
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Doğruladım, Giriş Yap'),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),

              // Bilgi notu
              Text(
                'E-postayı bulamıyor musun? Spam/gereksiz klasörünü kontrol et.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
