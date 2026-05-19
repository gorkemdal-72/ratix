import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;
  
  @override
  void initState() {
    super.initState();
    
    // Kullanıcının e-posta durumunu al
    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    
    if (!isEmailVerified) {
      // Her 3 saniyede bir e-postanın doğrulanıp doğrulanmadığını kontrol et
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    // Firebase auth kullanıcısını yeniden yükle
    await FirebaseAuth.instance.currentUser?.reload();
    
    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });
    
    // Eğer doğrulandıysa zamanlayıcıyı iptal et
    if (isEmailVerified) {
      timer?.cancel();
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      
      setState(() => canResendEmail = false);
      
      // 5 saniye sonra tekrar göndermeye izin ver
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) setState(() => canResendEmail = true);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğrulama e-postası tekrar gönderildi!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer email doğrulandıysa burayı hiç çizme, main.dart'taki StreamBuilder
    // algılayıp direkt HomeScreen'e yönlendirecek, ama biz yine de güvenli olsun diye
    // ekranda bekliyoruz mesajı verebiliriz.
    if (isEmailVerified) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 80, color: AppTheme.success),
              const SizedBox(height: 16),
              Text(
                "E-postanız onaylandı!",
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Yönlendiriliyorsunuz..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("E-Posta Doğrulama"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXl),
              Text(
                "Lütfen e-postanızı kontrol edin",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceMd),
              Text(
                "Hesabınızı aktifleştirmek için ${FirebaseAuth.instance.currentUser?.email ?? 'e-posta adresinize'} bir doğrulama bağlantısı gönderdik.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceLg),
              const CircularProgressIndicator(),
              const SizedBox(height: AppTheme.spaceMd),
              const Text("Onay bekleniyor..."),
              const SizedBox(height: AppTheme.spaceXl),
              
              // Tekrar Gönder Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canResendEmail ? sendVerificationEmail : null,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text("Tekrar Gönder"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              
              // Çıkış Yap Butonu
              TextButton(
                onPressed: () => AuthService().signOut(),
                child: const Text("İptal (Çıkış Yap)"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
