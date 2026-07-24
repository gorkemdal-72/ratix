import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/social_service.dart';
import '../../models/user_model.dart';
import 'social_profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final String username;
  final bool showFollowersFirst;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.username,
    this.showFollowersFirst = true,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _followers = [];
  List<UserModel> _following = [];
  Set<String> _myFollowingIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.showFollowersFirst ? 0 : 1,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<SocialService>();
      final myId = service.currentUserId;

      final followersList = await service.getFollowers(widget.userId);
      final followingList = await service.getFollowing(widget.userId);
      
      Set<String> followingIds = {};
      if (myId != null) {
        followingIds = await service.getFollowingIds(myId);
      }

      if (mounted) {
        setState(() {
          _followers = followersList;
          _following = followingList;
          _myFollowingIds = followingIds;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow(UserModel user) async {
    final service = context.read<SocialService>();
    final myId = service.currentUserId;
    if (myId == null || myId == user.id) return;

    final isFollowing = _myFollowingIds.contains(user.id);

    setState(() {
      if (isFollowing) {
        _myFollowingIds.remove(user.id);
      } else {
        _myFollowingIds.add(user.id);
      }
    });

    try {
      if (isFollowing) {
        await service.unfollowUser(user.id);
      } else {
        await service.followUser(user.id);
      }
    } catch (_) {
      // Revert if error
      if (mounted) {
        setState(() {
          if (isFollowing) {
            _myFollowingIds.add(user.id);
          } else {
            _myFollowingIds.remove(user.id);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('@${widget.username}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Takipçiler'),
            Tab(text: 'Takip Edilenler'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(_followers),
                _buildUserList(_following),
              ],
            ),
    );
  }

  Widget _buildUserList(List<UserModel> users) {
    if (users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Gösterilecek kullanıcı bulunamadı.'),
        ),
      );
    }

    final service = context.read<SocialService>();
    final myId = service.currentUserId;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final u = users[index];
          final isMe = u.id == myId;
          final isFollowing = _myFollowingIds.contains(u.id);

          return ListTile(
            leading: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => SocialProfileScreen(userId: u.id),
              )),
              child: CircleAvatar(
                backgroundImage: u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                child: u.avatarUrl == null ? const Icon(Icons.person) : null,
              ),
            ),
            title: Text(
              u.displayName ?? 'İsimsiz',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('@${u.username ?? 'user'}'),
            trailing: isMe
                ? null
                : SizedBox(
                    width: 110,
                    child: ElevatedButton(
                      onPressed: () => _toggleFollow(u),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: isFollowing
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        isFollowing ? 'Takibi Bırak' : 'Takip Et',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => SocialProfileScreen(userId: u.id),
            )),
          );
        },
      ),
    );
  }
}
