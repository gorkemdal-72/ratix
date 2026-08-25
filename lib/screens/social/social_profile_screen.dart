import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/social_service.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import 'widgets/post_card.dart';
import 'edit_profile_screen.dart';
import 'follow_list_screen.dart';
import 'fullscreen_avatar_screen.dart';
import '../admin/admin_reports_screen.dart';
import '../diary/diary_screen.dart';
import '../../core/app_strings.dart';

class SocialProfileScreen extends StatefulWidget {
  final String userId;
  const SocialProfileScreen({super.key, required this.userId});

  @override
  State<SocialProfileScreen> createState() => _SocialProfileScreenState();
}

class _SocialProfileScreenState extends State<SocialProfileScreen> {
  UserModel? _profile;
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isBlocked = false;

  // Mevcut kullanıcının admin bilgisi
  bool _currentIsAdmin = false;
  bool _currentIsSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<SocialService>();
      final adminService = context.read<AdminService>();
      final profile = await service.getUserProfile(widget.userId);
      final posts = await service.getUserPosts(widget.userId);
      bool following = false;
      bool blocked = false;
      if (service.currentUserId != null && service.currentUserId != widget.userId) {
        following = await service.isFollowing(widget.userId);
        blocked = await service.isBlocked(widget.userId);
      }

      // Mevcut kullanıcının admin bilgisi
      final myProfile = await adminService.getCurrentUserProfile(forceRefresh: true);
      
      if (mounted) {
        setState(() {
          _profile = profile;
          _posts = posts;
          _isFollowing = following;
          _isBlocked = blocked;
          _currentIsAdmin = myProfile?.hasAdminPrivileges ?? false;
          _currentIsSuperAdmin = myProfile?.isSuperAdmin ?? false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isTogglingFollow = false;

  void _toggleFollow() async {
    if (_isTogglingFollow) return;
    final service = context.read<SocialService>();
    if (service.currentUserId == null) return;
    
    setState(() {
      _isTogglingFollow = true;
      _isFollowing = !_isFollowing;
    });
    try {
      if (_isFollowing) {
        await service.followUser(widget.userId);
      } else {
        await service.unfollowUser(widget.userId);
      }
    } catch (_) {
      if (mounted) setState(() => _isFollowing = !_isFollowing);
    } finally {
      if (mounted) setState(() => _isTogglingFollow = false);
    }
  }

  // ─── Admin Aksiyonları ───

  void _showAdminActions() {
    final isTargetAdmin = _profile?.isAdmin ?? false;
    final isTargetVerified = _profile?.isVerified ?? false;
    final isTargetMuted = _profile?.isMuted ?? false;
    final isTargetBanned = _profile?.isBanned ?? false;
    final isTargetShadowbanned = _profile?.isShadowbanned ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('🛡️ Admin İşlemleri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),

              // ─── Uyarı Gönder (Admin + Süper Admin) ───
              ListTile(
                leading: const Icon(Icons.warning_amber, color: Colors.orange),
                title: const Text('Uyarı Gönder'),
                subtitle: const Text('Kullanıcıya uyarı bildirimi gönder'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showWarnDialog();
                },
              ),

              // ─── Sustur / Kaldır (Admin + Süper Admin) ───
              if (isTargetMuted)
                ListTile(
                  leading: const Icon(Icons.volume_up, color: Colors.green),
                  title: const Text('Susturmayı Kaldır'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final success = await context.read<AdminService>().unmuteUser(widget.userId);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Susturma kaldırıldı ✓')));
                      _loadProfile();
                    }
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.volume_off, color: Colors.orange),
                  title: const Text('Sustur'),
                  subtitle: const Text('Kullanıcının yazmasını geçici engelle'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMuteDialog();
                  },
                ),

              // ─── Uyarı Geçmişi ───
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blueGrey),
                title: const Text('Uyarı Geçmişi'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showWarningHistory();
                },
              ),

              const Divider(),

              // ─── Süper Admin Only ───
              if (_currentIsSuperAdmin) ...[
                // Admin Yap / Kaldır
                if (isTargetAdmin)
                  ListTile(
                    leading: const Icon(Icons.remove_moderator, color: Colors.red),
                    title: const Text('Admin Yetkisini Kaldır'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final success = await context.read<AdminService>().revokeAdmin(widget.userId);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin yetkisi kaldırıldı')));
                        context.read<AdminService>().clearCache();
                        await Future.delayed(const Duration(milliseconds: 500));
                        _loadProfile();
                      }
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.shield, color: Colors.blue),
                    title: const Text('Admin Yap'),
                    subtitle: const Text('Bu kullanıcıya moderasyon yetkisi ver'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final success = await context.read<AdminService>().grantAdmin(widget.userId);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin yetkisi verildi 🛡️')));
                        context.read<AdminService>().clearCache();
                        await Future.delayed(const Duration(milliseconds: 500));
                        _loadProfile();
                      }
                    },
                  ),

                // Verified Rozet
                if (isTargetVerified)
                  ListTile(
                    leading: Icon(Icons.verified, color: Colors.blue.shade400),
                    title: const Text('Doğrulanmış Rozetini Kaldır'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final success = await context.read<AdminService>().unverifyUser(widget.userId);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rozet kaldırıldı')));
                        _loadProfile();
                      }
                    },
                  )
                else
                  ListTile(
                    leading: Icon(Icons.verified_outlined, color: Colors.blue.shade400),
                    title: const Text('Doğrulanmış Rozet Ver'),
                    subtitle: const Text('Hesabı onaylı olarak işaretle'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final success = await context.read<AdminService>().verifyUser(widget.userId);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doğrulanmış rozeti verildi ✓')));
                        _loadProfile();
                      }
                    },
                  ),

                // Shadowban / Unshadowban (Süper Admin)
                if (isTargetShadowbanned)
                  ListTile(
                    leading: const Icon(Icons.visibility, color: Colors.green),
                    title: const Text('Shadowban Kaldır'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final success = await context.read<AdminService>().unshadowbanUser(widget.userId);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shadowban kaldırıldı')));
                        _loadProfile();
                      }
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.visibility_off, color: Colors.grey),
                    title: const Text('Shadowban Uygula'),
                    subtitle: const Text('Kullanıcıyı çaktırmadan uzaklaştır'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final success = await context.read<AdminService>().shadowbanUser(widget.userId);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shadowban uygulandı 👻')));
                        _loadProfile();
                      }
                    },
                  ),

                // Ban / Unban
                if (isTargetBanned)
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                    title: const Text('Banı Kaldır'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final success = await context.read<AdminService>().unbanUser(widget.userId);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ban kaldırıldı')));
                        _loadProfile();
                      }
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.block, color: Colors.red),
                    title: const Text('Kalıcı Banla'),
                    subtitle: const Text('Kullanıcıyı platformdan tamamen uzaklaştır'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showBanDialog();
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

  void _showWarnDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('⚠️ @${_profile?.username ?? 'user'} Uyar'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Uyarı sebebi',
            hintText: 'Kurallara aykırı davranış...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              final success = await context.read<AdminService>().sendWarning(widget.userId, reason);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uyarı gönderildi ⚠️')));
              }
            },
            child: const Text('Uyarı Gönder'),
          ),
        ],
      ),
    );
  }

  void _showMuteDialog() {
    Duration selectedDuration = const Duration(hours: 24);
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('🔇 @${_profile?.username ?? 'user'} Sustur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Duration>(
                initialValue: selectedDuration,
                decoration: const InputDecoration(labelText: 'Süre'),
                items: const [
                  DropdownMenuItem(value: Duration(hours: 24), child: Text('24 Saat')),
                  DropdownMenuItem(value: Duration(days: 3), child: Text('3 Gün')),
                  DropdownMenuItem(value: Duration(days: 7), child: Text('1 Hafta')),
                  DropdownMenuItem(value: Duration(days: 30), child: Text('1 Ay')),
                ],
                onChanged: (v) => setDialogState(() => selectedDuration = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Sebep',
                  hintText: 'Sürekli spam yapıyor...',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) return;
                Navigator.pop(ctx);
                final success = await context.read<AdminService>().muteUser(widget.userId, selectedDuration, reason);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı susturuldu 🔇')));
                  _loadProfile();
                }
              },
              child: const Text('Sustur'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBanDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('🚫 @${_profile?.username ?? 'user'} Kalıcı Banla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bu işlem geri alınabilir ama kullanıcı platforma erişemeyecek.', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Ban sebebi',
                hintText: 'Spam bot, zararlı içerik...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              final success = await context.read<AdminService>().banUser(widget.userId, reason);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı banlandı 🚫'), backgroundColor: Colors.red));
                _loadProfile();
              }
            },
            child: const Text('Banla'),
          ),
        ],
      ),
    );
  }

  void _showWarningHistory() async {
    final warnings = await context.read<AdminService>().getUserWarnings(widget.userId);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('📋 @${_profile?.username ?? 'user'} Uyarı Geçmişi'),
        content: SizedBox(
          width: double.maxFinite,
          child: warnings.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Hiç uyarı almamış 🎉')))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: warnings.length,
                  itemBuilder: (ctx, i) {
                    final w = warnings[i];
                    final adminInfo = w['users'] as Map<String, dynamic>?;
                    final date = DateTime.tryParse(w['created_at'] ?? '');
                    return ListTile(
                      leading: const Icon(Icons.warning_amber, color: Colors.orange),
                      title: Text(w['reason'] ?? ''),
                      subtitle: Text(
                        '${adminInfo?['display_name'] ?? adminInfo?['username'] ?? 'Admin'} • ${date != null ? "${date.day}/${date.month}/${date.year}" : ""}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat'))],
      ),
    );
  }

  void _showReportDialog() {
    String selectedReason = 'spam';
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (innerCtx, setState) => AlertDialog(
          title: const Text('Kullanıcıyı Şikayet Et'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                decoration: const InputDecoration(labelText: 'Sebep'),
                items: const [
                  DropdownMenuItem(value: 'spam', child: Text('🚫 Spam / Sahte Hesap')),
                  DropdownMenuItem(value: 'harassment', child: Text('😡 Taciz / Zorbalık')),
                  DropdownMenuItem(value: 'inappropriate', child: Text('🔞 Uygunsuz Profil/İçerik')),
                  DropdownMenuItem(value: 'other', child: Text('📝 Diğer')),
                ],
                onChanged: (v) => setState(() => selectedReason = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (opsiyonel)',
                  hintText: 'Daha fazla bilgi ekle...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await context.read<AdminService>().submitReport(
                  reportedUserId: widget.userId,
                  reason: selectedReason,
                  details: detailsController.text.isNotEmpty ? detailsController.text : null,
                );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kullanıcı şikayet edildi. Teşekkürler! 🛡️')),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şikayet gönderilemedi, lütfen tekrar deneyin.')),
                  );
                }
              },
              child: const Text('Raporla'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_profile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Kullanıcı bulunamadı.', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Geri Dön'),
                onPressed: () async {
                  await context.read<AuthService>().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              )
            ],
          ),
        ),
      );
    }

    final isMe = context.read<SocialService>().currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_profile!.username ?? 'Profil'),
            const SizedBox(width: 4),
            ..._buildProfileBadges(),
          ],
        ),
        actions: [
          // Block actions for non-own profile
          if (!isMe)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'block_toggle') {
                  if (_isBlocked) {
                    await context.read<SocialService>().unblockUser(widget.userId);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Engel kaldırıldı.')));
                    _loadProfile();
                  } else {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Kullanıcıyı Engelle'),
                        content: const Text('Bu kullanıcıyı engellemek istediğinize emin misiniz? Birbirinizi takip edemez ve gönderilerini göremezsiniz.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Engelle', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await context.read<SocialService>().blockUser(widget.userId);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı engellendi.')));
                      _loadProfile();
                    }
                  }
                } else if (value == 'report') {
                  _showReportDialog();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'block_toggle',
                  child: Text(_isBlocked ? 'Engeli Kaldır' : 'Engelle', style: TextStyle(color: _isBlocked ? Colors.blue : Colors.red)),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Şikayet Et'),
                ),
              ],
            ),
          // Admin işlemleri butonu (sadece admin ise ve başkasının profili ise)
          if (_currentIsAdmin && !isMe)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin İşlemleri',
              onPressed: _showAdminActions,
            ),
          // Admin Paneli butonu (sadece admin ise ve kendi profili ise)
          if (_currentIsAdmin && isMe)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Paneli',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const AdminReportsScreen(),
                ));
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_profile!.avatarUrl != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => FullscreenAvatarScreen(
                          avatarUrl: _profile!.avatarUrl,
                          heroTag: 'avatar_${_profile!.avatarUrl}',
                        ),
                      ));
                    }
                  },
                  child: Hero(
                    tag: 'avatar_${_profile!.avatarUrl}',
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: _profile!.avatarUrl != null ? NetworkImage(_profile!.avatarUrl!) : null,
                      child: _profile!.avatarUrl == null ? const Icon(Icons.person, size: 40) : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(AppStrings.isEn ? 'Posts' : 'Gönderi', _profile!.postsCount),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => FollowListScreen(
                                  userId: widget.userId,
                                  username: _profile!.username ?? 'user',
                                  showFollowersFirst: true,
                                ),
                              ));
                              _loadProfile();
                            },
                            child: _buildStatColumn(AppStrings.followers, _profile!.followersCount),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => FollowListScreen(
                                  userId: widget.userId,
                                  username: _profile!.username ?? 'user',
                                  showFollowersFirst: false,
                                ),
                              ));
                              _loadProfile();
                            },
                            child: _buildStatColumn(AppStrings.following, _profile!.followingCount),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isBlocked)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: const Text('Bu kullanıcıyı engellediniz.', textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
                        )
                      else if (!isMe)
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _toggleFollow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFollowing ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Theme.of(context).colorScheme.primary,
                                  foregroundColor: _isFollowing ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onPrimary,
                                  elevation: 0,
                                ),
                                child: Text(_isFollowing ? AppStrings.unfollow : AppStrings.follow),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDiaryButton(),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    try {
                                      final updated = await Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => EditProfileScreen(profile: _profile!),
                                      ));
                                      if (updated == true) {
                                        _loadProfile();
                                      }
                                    } catch (e, stack) {
                                      debugPrint("NAVIGATE ERROR: $e");
                                      debugPrint(stack.toString());
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Yönlendirme hatası: $e')),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(AppStrings.editProfile),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () async {
                                  await context.read<AuthService>().signOut();
                                },
                                icon: const Icon(Icons.logout),
                                color: Theme.of(context).colorScheme.error,
                                tooltip: 'Çıkış Yap',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // İsim + Badge satırı
            Row(
              children: [
                Text(_profile!.displayName ?? 'İsimsiz', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 4),
                ..._buildProfileBadges(),
              ],
            ),

            // Muted / Banned durum göstergesi (sadece admin görür)
            if (_currentIsAdmin) ...[
              if (_profile!.isMuted)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.volume_off, color: Colors.orange, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Susturulmuş (${_profile!.muteReason ?? ""})',
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              if (_profile!.isBanned)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block, color: Colors.red, size: 16),
                      SizedBox(width: 6),
                      Text('Kalıcı Banlı', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  ),
                ),
            ],

            if (_profile!.bio != null && _profile!.bio!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_profile!.bio!),
            ],
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),
            const Text('Gönderiler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Builder(builder: (ctx) {
              final isMyProfile = context.read<SocialService>().currentUserId == widget.userId;
              final bool isPrivate = _profile!.diaryVisibility == 'private';
              final bool isFollowersOnly = _profile!.diaryVisibility == 'followers_only';
              
              final bool canSeePosts = isMyProfile || 
                (!isPrivate && !(isFollowersOnly && !_isFollowing));

              if (_isBlocked) {
                return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Gönderiler gizli.')));
              } else if (!canSeePosts) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.lock_outline, size: 48, color: Theme.of(context).disabledColor),
                        const SizedBox(height: 16),
                        const Text('Bu hesap gizli.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          isPrivate ? 'Bu kullanıcının gönderilerini kimse göremiyor.' : 'Gönderileri görmek için takip etmelisin.',
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              } else if (_posts.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Henüz gönderi yok.')));
              } else {
                return Column(
                  children: _posts.map((post) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PostCard(post: post, onDelete: _loadProfile),
                  )).toList(),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProfileBadges() {
    if (_profile == null) return [];
    List<Widget> badges = [];
    
    if (_profile!.badgeEmoji != null && _profile!.badgeEmoji!.isNotEmpty) {
      badges.add(Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(_profile!.badgeEmoji!, style: const TextStyle(fontSize: 16)),
      ));
    } else {
      if (_profile!.isSuperAdmin) {
        badges.add(const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('👑', style: TextStyle(fontSize: 16)),
        ));
      } else if (_profile!.isAdmin) {
        badges.add(const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('🛡️', style: TextStyle(fontSize: 16)),
        ));
      }
    }

    if (_profile!.isVerified) {
      badges.add(Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(Icons.verified, size: 18, color: Colors.blue.shade400),
      ));
    }
    return badges;
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildDiaryButton() {
    final visibility = _profile?.diaryVisibility ?? 'followers_only';
    
    bool canView = false;
    if (_currentIsAdmin || _currentIsSuperAdmin) {
      canView = true;
    } else if (visibility == 'public') {
      canView = true;
    } else if (visibility == 'followers_only' && _isFollowing) {
      canView = true;
    }

    if (visibility == 'private' && !_currentIsAdmin && !_currentIsSuperAdmin) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.lock, size: 18),
          label: const Text('Günlük Gizli'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: canView ? () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => DiaryScreen(
              userId: widget.userId,
              username: _profile?.username,
            ),
          ));
        } : () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu günlüğü görmek için takip etmelisin.')));
        },
        icon: Icon(canView ? Icons.book : Icons.lock_outline, size: 18),
        label: const Text('Günlüğü Görüntüle'),
      ),
    );
  }
}
