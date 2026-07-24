import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/social_service.dart';
import '../../models/user_model.dart';
import '../../core/app_theme.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<UserModel> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await context.read<SocialService>().getBlockedUsers();
      if (mounted) setState(() => _blockedUsers = users);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _unblockUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Engeli Kaldır'),
        content: Text('${user.displayName ?? user.username} adlı kullanıcının engelini kaldırmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaldır', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<SocialService>().unblockUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Engel kaldırıldı.')));
        _loadBlockedUsers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Engellenen Kullanıcılar')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? const Center(child: Text('Engellenen kullanıcı yok.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  itemCount: _blockedUsers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final u = _blockedUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                        child: u.avatarUrl == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(u.displayName ?? u.username ?? 'İsimsiz'),
                      subtitle: Text('@${u.username ?? ''}'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          elevation: 0,
                        ),
                        onPressed: () => _unblockUser(u),
                        child: const Text('Kaldır'),
                      ),
                    );
                  },
                ),
    );
  }
}
