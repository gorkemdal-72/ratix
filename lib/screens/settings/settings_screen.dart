import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';
import '../../core/app_strings.dart';
import '../../services/settings_service.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import 'blocked_users_screen.dart';
import 'legal_screens.dart' as legal;
import '../../services/admin_service.dart';
import '../admin/admin_reports_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _privateAccount = false;
  bool _showSharePrompt = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final showSharePrompt = prefs.getBool('show_quick_share_prompt') ?? true;
    final data = await _settingsService.getUserData();
    final isAdmin = await Provider.of<AdminService>(context, listen: false).isCurrentUserAdmin();
    
    if (data != null && mounted) {
      setState(() {
        if (data['preferences'] != null) {
          bool isDark = data['preferences']['defaultTheme'] ?? false;
          Provider.of<ThemeProvider>(context, listen: false).toggleTheme(isDark);
        }
        
        _privateAccount = data['diary_visibility'] == 'followers_only' || data['diary_visibility'] == 'private';
        _showSharePrompt = showSharePrompt;
        _isAdmin = isAdmin;
        _isLoading = false; 
      });
    } else {
      if (mounted) {
        setState(() {
          _showSharePrompt = showSharePrompt;
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
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



  Widget _buildGeneralSection() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          SwitchListTile(
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
            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
          ),
          const Divider(height: 1, thickness: 1),
          SwitchListTile(
            title: const Text("Anlık Bildirimler"),
            subtitle: Text(
              _notificationsEnabled ? "Bildirimler açık" : "Bildirimler kapalı",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? 'Bildirimler açıldı' : 'Bildirimler kapatıldı')));
            },
            secondary: Icon(
              _notificationsEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
          ),
          const Divider(height: 1, thickness: 1),
          SwitchListTile(
            title: const Text("Gizli Hesap"),
            subtitle: Text(
              _privateAccount ? "Profilini sadece takipçilerin görebilir" : "Profilin herkese açık",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: _privateAccount,
            onChanged: (value) async {
              setState(() => _privateAccount = value);
              await _settingsService.updateDiaryVisibility(value ? 'followers_only' : 'public');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? 'Hesabın gizliye alındı' : 'Hesabın herkese açık yapıldı')));
              }
            },
            secondary: Icon(
              _privateAccount ? Icons.lock_rounded : Icons.public_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
          ),
          const Divider(height: 1, thickness: 1),
          SwitchListTile(
            title: const Text("Paylaşım Tercihi"),
            subtitle: Text(
              _showSharePrompt ? "Listeye öğe eklenince paylaşım penceresi gösterilir" : "Listeye öğe eklenince paylaşım penceresi gösterilmez",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: _showSharePrompt,
            onChanged: (value) async {
              setState(() => _showSharePrompt = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('show_quick_share_prompt', value);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(value ? 'Paylaşım önerisi açıldı' : 'Paylaşım önerisi kapatıldı')),
                );
              }
            },
            secondary: Icon(
              _showSharePrompt ? Icons.share_rounded : Icons.share_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
          ),
          const Divider(height: 1, thickness: 1),
          ListTile(
            title: const Text("Dil Seçeneği"),
            subtitle: Text("Şu anki dil: Türkçe", style: Theme.of(context).textTheme.bodySmall),
            leading: Icon(Icons.language_rounded, color: Theme.of(context).colorScheme.primary),
            trailing: const Icon(Icons.chevron_right_rounded),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dil seçeneği çok yakında eklenecek!")));
            },
          ),
          const Divider(height: 1, thickness: 1),
          ListTile(
            title: const Text('Engellenen Kullanıcılar'),
            subtitle: Text('Engellediğin kullanıcıları yönet', style: Theme.of(context).textTheme.bodySmall),
            leading: Icon(Icons.block_rounded, color: Theme.of(context).colorScheme.primary),
            trailing: const Icon(Icons.chevron_right_rounded),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen()));
            },
          ),
          if (_isAdmin) ...[
            const Divider(height: 1, thickness: 1),
            ListTile(
              title: const Text('Moderasyon Paneli', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              subtitle: Text('Şikayetleri yönet ve aksiyon al', style: Theme.of(context).textTheme.bodySmall),
              leading: const Icon(Icons.security, color: Colors.redAccent),
              trailing: const Icon(Icons.chevron_right_rounded),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsScreen()));
              },
            ),
          ],
        ],
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
          // About Section Header Logo
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/icon.png', fit: BoxFit.cover),
            ),
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
          Text(
            "Sürüm 4.0.1",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          // Hakkında metni
          Text(
            AppStrings.aboutApp.replaceAll('Ratix v4.0.1\n', ''),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).colorScheme.primary),
            title: const Text("Gizlilik Politikası"),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            contentPadding: EdgeInsets.zero,
            dense: true,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const legal.PrivacyPolicyScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.primary),
            title: const Text("Kullanım Koşulları"),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            contentPadding: EdgeInsets.zero,
            dense: true,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const legal.TermsOfServiceScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.support_agent_rounded, color: Theme.of(context).colorScheme.primary),
            title: const Text("Destek ve İletişim"),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            contentPadding: EdgeInsets.zero,
            dense: true,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const legal.SupportContactScreen()));
            },
          ),
          const SizedBox(height: 16),
          Text(
            "© 2026 Ratix. Tüm Hakları Saklıdır.",
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
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