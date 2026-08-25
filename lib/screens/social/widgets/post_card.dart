import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/post_model.dart';
import '../../../services/social_service.dart';
import '../../../services/admin_service.dart';
import '../post_detail_screen.dart';
import '../social_profile_screen.dart';
import '../../../core/app_strings.dart';
import 'package:intl/intl.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onDelete;
  const PostCard({super.key, required this.post, this.onDelete});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likeCount;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByMe;
    _likeCount = widget.post.likeCount;
    _checkAdminStatus();
  }

  void _checkAdminStatus() async {
    final adminService = context.read<AdminService>();
    final profile = await adminService.getCurrentUserProfile();
    if (mounted && profile != null) {
      setState(() {
        _isAdmin = profile.hasAdminPrivileges;
      });
    }
  }

  void _confirmDelete(BuildContext context, {bool asAdmin = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.deletePost),
        content: Text(asAdmin
            ? (AppStrings.isEn ? 'Are you sure you want to delete this post as Admin?' : 'Admin olarak bu gönderiyi silmek istediğinizden emin misiniz?')
            : AppStrings.deletePostConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (asAdmin) {
                await context.read<AdminService>().adminDeletePost(widget.post.id);
              } else {
                await context.read<SocialService>().deletePost(widget.post.id);
              }
              if (widget.onDelete != null) {
                widget.onDelete!();
              }
            },
            child: Text(AppStrings.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    String selectedReason = 'spam';
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(AppStrings.reportPost),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                decoration: InputDecoration(labelText: AppStrings.reason),
                items: [
                  DropdownMenuItem(value: 'spam', child: Text(AppStrings.isEn ? '🚫 Spam' : '🚫 Spam')),
                  DropdownMenuItem(value: 'spoiler', child: Text(AppStrings.isEn ? '⚠️ Spoiler' : '⚠️ Spoiler')),
                  DropdownMenuItem(value: 'inappropriate', child: Text(AppStrings.isEn ? '🔞 Inappropriate Content' : '🔞 Uygunsuz İçerik')),
                  DropdownMenuItem(value: 'harassment', child: Text(AppStrings.isEn ? '😡 Harassment / Bullying' : '😡 Taciz / Zorbalık')),
                  DropdownMenuItem(value: 'other', child: Text(AppStrings.isEn ? '📝 Other' : '📝 Diğer')),
                ],
                onChanged: (v) => setState(() => selectedReason = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: InputDecoration(
                  labelText: AppStrings.descriptionOptional,
                  hintText: AppStrings.isEn ? 'Add more info...' : 'Daha fazla bilgi ekle...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await context.read<AdminService>().submitReport(
                  postId: widget.post.id,
                  reportedUserId: widget.post.userId,
                  reason: selectedReason,
                  details: detailsController.text.isNotEmpty ? detailsController.text : null,
                );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppStrings.reportSent)),
                  );
                }
              },
              child: Text(AppStrings.report),
            ),
          ],
        ),
      ),
    );
  }

  bool _isLoadingLike = false;

  void _toggleLike() async {
    if (_isLoadingLike) return;
    setState(() {
      _isLoadingLike = true;
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    try {
      await context.read<SocialService>().togglePostLike(widget.post.id, widget.post.userId, !_isLiked);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingLike = false);
    }
  }

  /// Kullanıcı adının yanında admin/verified badge gösterir
  Widget _buildUserBadges(Post post) {
    final user = post.user;
    if (user == null) return const SizedBox.shrink();

    List<Widget> badges = [];

    // Custom badge, yoksa varsayılan
    if (user.badgeEmoji != null && user.badgeEmoji!.isNotEmpty) {
      badges.add(Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(user.badgeEmoji!, style: const TextStyle(fontSize: 14)),
      ));
    } else {
      // Süper Admin badge
      if (user.isSuperAdmin) {
        badges.add(const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('👑', style: TextStyle(fontSize: 14)),
        ));
      }
      // Admin badge
      else if (user.isAdmin) {
        badges.add(const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('🛡️', style: TextStyle(fontSize: 14)),
        ));
      }
    }

    // Verified badge
    if (user.isVerified) {
      badges.add(Padding(
        padding: const EdgeInsets.only(left: 3),
        child: Icon(Icons.verified, size: 16, color: Colors.blue.shade400),
      ));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: badges);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.post.user;
    final item = widget.post.item;
    final isOwner = context.read<SocialService>().currentUserId == widget.post.userId;

    return Card(
      elevation: widget.post.isEditorsChoice ? 2 : 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: widget.post.isEditorsChoice 
              ? Colors.orange.shade300 
              : Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: widget.post.isEditorsChoice ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => PostDetailScreen(post: widget.post),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.post.isEditorsChoice)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(AppStrings.editorsChoice, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                    ],
                  ),
                ),
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (user != null) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => SocialProfileScreen(userId: user.id),
                        ));
                      }
                    },
                    child: CircleAvatar(
                      backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                      child: user?.avatarUrl == null ? const Icon(Icons.person) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(user?.displayName ?? AppStrings.anonymousUser, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            ),
                            _buildUserBadges(widget.post),
                          ],
                        ),
                        Text('@${user?.username ?? 'user'} • ${DateFormat.yMMMd(AppStrings.isEn ? 'en_US' : 'tr_TR').format(widget.post.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  // Menü: sahibi, admin veya normal kullanıcı
                  PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'delete') {
                        _confirmDelete(context);
                      } else if (val == 'admin_delete') {
                        _confirmDelete(context, asAdmin: true);
                      } else if (val == 'report') {
                        _showReportDialog(context);
                      } else if (val == 'editor_choice_add') {
                        final success = await context.read<AdminService>().toggleEditorsChoice(widget.post.id, true);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editörün Seçimi yapıldı 🌟')));
                          if (widget.onDelete != null) widget.onDelete!();
                        }
                      } else if (val == 'editor_choice_remove') {
                        final success = await context.read<AdminService>().toggleEditorsChoice(widget.post.id, false);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editörün Seçimi kaldırıldı')));
                          if (widget.onDelete != null) widget.onDelete!();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      if (isOwner)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(AppStrings.delete, style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      if (_isAdmin) ...[
                        if (widget.post.isEditorsChoice)
                          PopupMenuItem(
                            value: 'editor_choice_remove',
                            child: Row(
                              children: [
                                const Icon(Icons.star_border, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(AppStrings.isEn ? 'Remove Editor\'s Choice' : 'Editörün Seçimi Kaldır', style: const TextStyle(color: Colors.orange)),
                              ],
                            ),
                          )
                        else
                          PopupMenuItem(
                            value: 'editor_choice_add',
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text('🌟 ${AppStrings.editorsChoice}', style: const TextStyle(color: Colors.orange)),
                              ],
                            ),
                          ),
                        if (!isOwner)
                          PopupMenuItem(
                            value: 'admin_delete',
                            child: Row(
                              children: [
                                const Icon(Icons.gavel, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Text(AppStrings.isEn ? 'Admin Delete' : 'Admin Sil', style: const TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                      ],
                      if (!isOwner)
                        PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              const Icon(Icons.flag_outlined, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(AppStrings.report),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Content
              if (widget.post.content != null && widget.post.content!.isNotEmpty) ...[
                Text(widget.post.content!),
                const SizedBox(height: 12),
              ],

              // Item Reference
              if (item != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (item.posterUrl != null && item.posterUrl!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(item.posterUrl!, width: 48, height: 72, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                      ] else
                        Container(
                          width: 48,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.movie, size: 24),
                        ),
                      if (item.posterUrl == null) const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${AppStrings.rating}: ${item.rating}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Actions
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : null),
                    onPressed: _toggleLike,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Text('$_likeCount', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 24),
                  const IconButton(
                    icon: Icon(Icons.chat_bubble_outline),
                    onPressed: null,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Text('${widget.post.commentCount}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
