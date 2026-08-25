import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/app_theme.dart';
import '../../core/app_strings.dart';
import '../../models/user_model.dart';
import '../../services/settings_service.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import 'blocked_users_screen.dart';
import 'legal_screens.dart' as legal;
import '../../services/admin_service.dart';
import '../admin/admin_reports_screen.dart';
import '../social/edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  UserModel? _profile;
  String _appVersion = '4.2.2';
  String _diaryVisibility = 'public';
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
    
    String loadedVersion = '4.2.2';
    // Dynamic App Version from PackageInfo (pubspec.yaml)
    try {
      final info = await PackageInfo.fromPlatform();
      loadedVersion = info.version;
    } catch (e) {
      debugPrint('[SettingsScreen] PackageInfo error: $e');
    }

    final adminService = Provider.of<AdminService>(context, listen: false);
    final profile = await adminService.getCurrentUserProfile(forceRefresh: true);
    final data = await _settingsService.getUserData();
    final isAdmin = await adminService.isCurrentUserAdmin();
    
    if (mounted) {
      final vis = data?['diary_visibility'] ?? profile?.diaryVisibility ?? 'public';
      setState(() {
        _profile = profile;
        _appVersion = loadedVersion;
        _diaryVisibility = vis;
        if (data != null && data['preferences'] != null) {
          bool isDark = data['preferences']['defaultTheme'] ?? false;
          Provider.of<ThemeProvider>(context, listen: false).toggleTheme(isDark);
        }
        
        _privateAccount = (vis == 'followers_only' || vis == 'private');
        _showSharePrompt = showSharePrompt;
        _isAdmin = isAdmin;
        _isLoading = false; 
      });
    }
  }

  // Çıkış yapma fonksiyonu
  void _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.logout),
        content: Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.logout, style: const TextStyle(color: AppTheme.danger)),
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

  void _showLanguageSelector(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final currentCode = localeProvider.currentLanguageCode;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  AppStrings.selectLanguage,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Text('🇹🇷', style: TextStyle(fontSize: 24)),
                title: Text(AppStrings.turkish),
                trailing: currentCode == 'tr' ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary) : null,
                onTap: () {
                  localeProvider.setLocale(const Locale('tr', 'TR'));
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                title: Text(AppStrings.english),
                trailing: currentCode == 'en' ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary) : null,
                onTap: () {
                  localeProvider.setLocale(const Locale('en', 'US'));
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showDiaryVisibilitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    AppStrings.isEn ? 'Diary Visibility' : 'Günlük Gizliliği',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.visibility_rounded, color: AppTheme.accent),
                  title: Text(AppStrings.isEn ? 'Public' : 'Herkese Açık'),
                  subtitle: Text(AppStrings.isEn ? 'Everyone can see your diary entries' : 'Herkes günlük içeriklerinizi görebilir'),
                  trailing: _diaryVisibility == 'public'
                      ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => _updateVisibility('public', ctx),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.group_rounded, color: Theme.of(context).colorScheme.primary),
                  title: Text(AppStrings.isEn ? 'Followers Only' : 'Sadece Takipçiler'),
                  subtitle: Text(AppStrings.isEn ? 'Only followers can see your diary' : 'Sadece takipçileriniz günlüğünüzü görebilir'),
                  trailing: _diaryVisibility == 'followers_only'
                      ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => _updateVisibility('followers_only', ctx),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: AppTheme.warning),
                  title: Text(AppStrings.isEn ? 'Only Me (Private)' : 'Herkesten Gizli (Sadece Ben)'),
                  subtitle: Text(AppStrings.isEn ? 'Completely private to you' : 'Günlüğünüz sadece size özeldir, kimse göremez'),
                  trailing: _diaryVisibility == 'private'
                      ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => _updateVisibility('private', ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateVisibility(String val, BuildContext ctx) async {
    Navigator.pop(ctx);
    final isPrivateAccount = val != 'public';
    setState(() {
      _diaryVisibility = val;
      _privateAccount = isPrivateAccount;
    });
    await _settingsService.updateDiaryVisibility(val);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            val == 'public'
                ? (AppStrings.isEn ? 'Diary is now public' : 'Günlük gizliliği herkese açık yapıldı')
                : val == 'followers_only'
                    ? (AppStrings.isEn ? 'Diary visible to followers only' : 'Günlük sadece takipçilere açıldı')
                    : (AppStrings.isEn ? 'Diary hidden from everyone (Only Me)' : 'Günlük herkesten gizlendi (Sadece Ben)'),
          ),
        ),
      );
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
      appBar: AppBar(title: Text(AppStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        children: [
          // ─── PROFİL & HESAP AYARLARI ───
          if (_profile != null) ...[
            _buildSectionHeader(AppStrings.profileInfo, Icons.person_outline_rounded),
            const SizedBox(height: AppTheme.spaceMd),
            _buildProfileSection(),
            const SizedBox(height: AppTheme.spaceLg),
          ],

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
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SwitchListTile(
              title: Text(AppStrings.darkMode),
              subtitle: Text(
                isDark
                    ? (AppStrings.isEn ? "Dark theme active" : "Karanlık tema aktif")
                    : (AppStrings.isEn ? "Light theme active" : "Aydınlık tema aktif"),
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
              title: Text(AppStrings.pushNotifications),
              subtitle: Text(
                _notificationsEnabled ? AppStrings.notificationsOn : AppStrings.notificationsOff,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? (AppStrings.isEn ? 'Notifications enabled' : 'Bildirimler açıldı')
                          : (AppStrings.isEn ? 'Notifications disabled' : 'Bildirimler kapatıldı'),
                    ),
                  ),
                );
              },
              secondary: Icon(
                _notificationsEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
            ),
            const Divider(height: 1, thickness: 1),
            SwitchListTile(
              title: Text(AppStrings.privateAccount),
              subtitle: Text(
                _privateAccount ? AppStrings.privateAccountSubOn : AppStrings.privateAccountSubOff,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: _privateAccount,
              onChanged: (value) async {
                final newVisibility = value ? 'followers_only' : 'public';
                setState(() {
                  _privateAccount = value;
                  _diaryVisibility = newVisibility;
                });
                await _settingsService.updateDiaryVisibility(newVisibility);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? (AppStrings.isEn ? 'Your account is now private' : 'Hesabın gizliye alındı (Günlük de otomatik gizlendi)')
                            : (AppStrings.isEn ? 'Your account is now public' : 'Hesabın herkese açık yapıldı'),
                      ),
                    ),
                  );
                }
              },
              secondary: Icon(
                _privateAccount ? Icons.lock_rounded : Icons.public_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
            ),
            const Divider(height: 1, thickness: 1),
            ListTile(
              title: Text(AppStrings.isEn ? 'Diary Visibility' : 'Günlük Gizliliği'),
              subtitle: Text(
                _diaryVisibility == 'public'
                    ? (AppStrings.isEn ? 'Everyone can see your diary' : 'Günlüğün herkese açık')
                    : _diaryVisibility == 'followers_only'
                        ? (AppStrings.isEn ? 'Only followers can see' : 'Günlüğünü sadece takipçilerin görebilir')
                        : (AppStrings.isEn ? 'Only me (Completely private)' : 'Herkesten gizli (Sadece sen görebilirsin)'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              leading: Icon(
                _diaryVisibility == 'public'
                    ? Icons.visibility_rounded
                    : _diaryVisibility == 'followers_only'
                        ? Icons.group_rounded
                        : Icons.lock_outline_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _diaryVisibility == 'public'
                          ? (AppStrings.isEn ? 'Public' : 'Açık')
                          : _diaryVisibility == 'followers_only'
                              ? (AppStrings.isEn ? 'Followers' : 'Takipçiler')
                              : (AppStrings.isEn ? 'Only Me' : 'Gizli'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              onTap: () => _showDiaryVisibilitySelector(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
            ),
            const Divider(height: 1, thickness: 1),
            SwitchListTile(
              title: Text(AppStrings.showSharePrompt),
              value: _showSharePrompt,
              onChanged: (value) async {
                setState(() => _showSharePrompt = value);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('show_quick_share_prompt', value);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? (AppStrings.isEn ? 'Share prompt enabled' : 'Paylaşım penceresi açıldı')
                            : (AppStrings.isEn ? 'Share prompt disabled' : 'Paylaşım penceresi kapatıldı'),
                      ),
                    ),
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
              title: Text(AppStrings.languageOption),
              subtitle: Text(AppStrings.currentLanguageSubtitle, style: Theme.of(context).textTheme.bodySmall),
              leading: Icon(Icons.language_rounded, color: Theme.of(context).colorScheme.primary),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localeProvider.isEnglish ? 'English' : 'Türkçe',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
              onTap: () => _showLanguageSelector(context),
            ),
            const Divider(height: 1, thickness: 1),
            ListTile(
              title: Text(AppStrings.blockedUsers),
              subtitle: Text(AppStrings.blockedUsersSub, style: Theme.of(context).textTheme.bodySmall),
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
                title: Text(
                  AppStrings.isEn ? 'Moderation Panel' : 'Moderasyon Paneli',
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  AppStrings.isEn ? 'Manage reports and take actions' : 'Şikayetleri yönet ve aksiyon al',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
      ),
    );
  }

  Widget _buildProfileSection() {
    final profile = _profile;
    if (profile == null) return const SizedBox.shrink();

    final avatarUrl = profile.avatarUrl;
    final displayName = profile.displayName ?? '';
    final username = profile.username ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Profil Kartı + Düzenle Butonu
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      )
                    : null,
              ),
              title: Text(
                displayName.isNotEmpty ? displayName : 'Kullanıcı',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text('@$username', style: Theme.of(context).textTheme.bodySmall),
              trailing: OutlinedButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text(AppStrings.edit),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
                  );
                  if (updated == true && mounted) {
                    _loadUserData();
                  }
                },
              ),
            ),
          ],
        ),
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
            "${AppStrings.isEn ? 'Version' : 'Sürüm'} $_appVersion",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          // Hakkında metni
          Text(
            AppStrings.aboutApp.replaceAll('Ratix v4.2.2\n', '').replaceAll('Ratix v4.0.1\n', '').replaceAll('Ratix v1.0.0\n', ''),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(AppStrings.privacyPolicy),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            contentPadding: EdgeInsets.zero,
            dense: true,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const legal.PrivacyPolicyScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(AppStrings.termsOfService),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            contentPadding: EdgeInsets.zero,
            dense: true,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const legal.TermsOfServiceScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.support_agent_rounded, color: Theme.of(context).colorScheme.primary),
            title: Text(AppStrings.supportContact),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            contentPadding: EdgeInsets.zero,
            dense: true,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const legal.SupportContactScreen()));
            },
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.copyright,
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
        label: Text(AppStrings.logout),
      ),
    );
  }
}