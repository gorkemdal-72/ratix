import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_theme.dart';
import '../../core/app_strings.dart';
import '../../widgets/avatar_upload_widget.dart';
import '../auth/login_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Çıkış yapma fonksiyonu
  Future<void> _signOut() async {
    // Onay diyaloğu göster
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.logout, style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()), 
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileTitle),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: AppStrings.logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spaceMd),

            // ─── PROFİL KARTI ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              decoration: BoxDecoration(
                gradient: isDark ? AppTheme.headerGradient : AppTheme.headerGradientLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppTheme.gradientStart).withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  AvatarUploadWidget(
                    radius: 50,
                    onUploadComplete: () {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(AppStrings.photoUpdated)),
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  // Kullanıcı adı
                  Text(
                    user?.displayName ?? user?.email?.split('@').first ?? AppStrings.guestUser,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceLg),

            // ─── BİLGİ KARTLARI ───
            _buildInfoCard(
              icon: Icons.email_outlined,
              label: AppStrings.email,
              value: user?.email ?? '-',
            ),
            const SizedBox(height: AppTheme.spaceSm),
            _buildInfoCard(
              icon: Icons.fingerprint_rounded,
              label: AppStrings.uid,
              value: user?.uid ?? '-',
            ),

            const SizedBox(height: AppTheme.spaceLg),

            // ─── ÇIKIŞ BUTONU ───
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text(AppStrings.logout),
              ),
            ),

            const SizedBox(height: AppTheme.spaceXl),

            // ─── MOTTO ───
            Text(
              AppStrings.profileMotto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}