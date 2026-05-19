import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/app_strings.dart';
import '../../services/settings_service.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/avatar_upload_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final data = await _settingsService.getUserData();
    
    if (data != null && mounted) {
      setState(() {
        _nameController.text = data['displayName'] ?? '';
        _bioController.text = data['bio'] ?? '';
        
        if (data['preferences'] != null) {
          bool isDark = data['preferences']['defaultTheme'] ?? false;
          Provider.of<ThemeProvider>(context, listen: false).toggleTheme(isDark);
        }
        
        _isLoading = false; 
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Çıkış yapma fonksiyonu
  void _logout(BuildContext context) async {
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
      await Provider.of<AuthService>(context, listen: false).signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
            strokeWidth: 3,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        children: [
          // ─── PROFİL BÖLÜMÜn ───
          _buildSectionHeader(AppStrings.profileInfo, Icons.person_outline_rounded),
          const SizedBox(height: AppTheme.spaceMd),
          _buildProfileSection(),

          const SizedBox(height: AppTheme.spaceLg),

          // ─── GENEL AYARLAR ───
          _buildSectionHeader(AppStrings.general, Icons.tune_rounded),
          const SizedBox(height: AppTheme.spaceMd),
          _buildGeneralSection(),

          const SizedBox(height: AppTheme.spaceLg),

          // ─── HAKKINDA ───
          _buildSectionHeader(AppStrings.aboutSection, Icons.info_outline_rounded),
          const SizedBox(height: AppTheme.spaceMd),
          _buildAboutSection(),

          const SizedBox(height: AppTheme.spaceLg),

          // ─── ÇIKIŞ BUTONU ───
          _buildLogoutButton(context),

          const SizedBox(height: AppTheme.spaceLg),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppTheme.spaceSm),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 17),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          // Avatar
          AvatarUploadWidget(
            radius: 44,
            onUploadComplete: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.photoUpdated)),
              );
              setState(() {});
            },
          ),
          const SizedBox(height: AppTheme.spaceMd),
          // İsim alanı
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: AppStrings.nameSurname,
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          // Bio alanı
          TextField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: AppStrings.about,
              prefixIcon: Icon(Icons.info_outline),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppTheme.spaceMd),
          // Kaydet butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _settingsService.updateProfileInfo(_nameController.text, _bioController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.profileSaved)),
                );
              },
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text(AppStrings.save),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSection() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: SwitchListTile(
        title: const Text(AppStrings.darkMode),
        subtitle: Text(
          isDark ? "Karanlık tema aktif" : "Aydınlık tema aktif",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: isDark,
        onChanged: (value) {
          Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
          _settingsService.updateThemePreference(value);
        },
        secondary: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: Tween(begin: 0.75, end: 1.0).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            key: ValueKey(isDark),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          // App ikonu
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Text(
            AppStrings.appName,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          // Hakkında metni
          Text(
            AppStrings.aboutApp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _logout(context), 
        icon: const Icon(Icons.logout_rounded),
        label: const Text(AppStrings.logout),
      ),
    );
  }
}