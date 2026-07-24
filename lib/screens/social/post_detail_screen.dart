import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../services/social_service.dart';
import '../../services/admin_service.dart';
import 'widgets/post_card.dart';
import 'package:intl/intl.dart';
import 'social_profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Post? post;
  final String? postId;
  const PostDetailScreen({super.key, this.post, this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  Post? _post;
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isLoadingPost = false;
  Comment? _replyingTo;

  // Admin durumu
  bool _isAdmin = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _checkAdminAndMuteStatus();
    if (_post == null && widget.postId != null) {
      _loadPost();
    } else if (_post != null) {
      _loadComments();
    } else {
      _isLoading = false;
    }
  }

  void _checkAdminAndMuteStatus() async {
    final adminService = context.read<AdminService>();
    final profile = await adminService.getCurrentUserProfile();
    if (mounted && profile != null) {
      setState(() {
        _isAdmin = profile.hasAdminPrivileges;
        _isMuted = profile.isMuted;
      });
    }
  }

  Future<void> _loadPost() async {
    setState(() => _isLoadingPost = true);
    try {
      final post = await context.read<SocialService>().getPostById(widget.postId!);
      if (mounted) {
        setState(() {
          _post = post;
          _isLoadingPost = false;
        });
        if (post != null) {
          _loadComments();
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingPost = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadComments() async {
    if (_post == null) return;
    setState(() => _isLoading = true);
    try {
      final comments = await context.read<SocialService>().getComments(_post!.id);
      if (mounted) setState(() => _comments = comments);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitComment() async {
    if (_post == null) return;
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    // Mute kontrolü
    if (_isMuted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesabınız susturulmuş durumda. Yorum yapamazsınız.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _commentController.clear();
    FocusScope.of(context).unfocus();

    await context.read<SocialService>().addComment(
      postId: _post!.id,
      postOwnerId: _post!.userId,
      content: content,
      parentId: _replyingTo?.id,
      parentOwnerId: _replyingTo?.userId,
    );

    setState(() => _replyingTo = null);
    _loadComments();
  }

  void _confirmDeleteComment(String commentId, {bool asAdmin = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yorumu Sil'),
        content: Text(asAdmin
            ? 'Admin olarak bu yorumu silmek istediğinizden emin misiniz?'
            : 'Bu yorumu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (asAdmin) {
                await context.read<AdminService>().adminDeleteComment(commentId);
              } else {
                await context.read<SocialService>().deleteComment(commentId);
              }
              _loadComments();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showWarnDialog(String targetUserId, String? username) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('⚠️ @${username ?? 'user'} Uyar'),
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
              final success = await context.read<AdminService>().sendWarning(targetUserId, reason);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Uyarı gönderildi ⚠️')),
                );
              }
            },
            child: const Text('Uyarı Gönder'),
          ),
        ],
      ),
    );
  }

  void _showReportCommentDialog(String commentId, String commentUserId) {
    String selectedReason = 'spam';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Yorumu Raporla'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedReason,
            decoration: const InputDecoration(labelText: 'Sebep'),
            items: const [
              DropdownMenuItem(value: 'spam', child: Text('🚫 Spam')),
              DropdownMenuItem(value: 'spoiler', child: Text('⚠️ Spoiler')),
              DropdownMenuItem(value: 'inappropriate', child: Text('🔞 Uygunsuz İçerik')),
              DropdownMenuItem(value: 'harassment', child: Text('😡 Taciz')),
            ],
            onChanged: (v) => setState(() => selectedReason = v!),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await context.read<AdminService>().submitReport(
                  commentId: commentId,
                  reportedUserId: commentUserId,
                  reason: selectedReason,
                );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rapor gönderildi 🛡️')),
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
    if (_isLoadingPost) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gönderi')),
        body: const Center(child: Text('Gönderi bulunamadı.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gönderi')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PostCard(
                  post: _post!,
                  onDelete: () {
                    Navigator.pop(context);
                  },
                ),
                const Divider(height: 32),
                const Text('Yorumlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_comments.isEmpty)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('İlk yorumu sen yap!')))
                else
                  ..._comments.map((c) => _buildCommentNode(c, 0)),
              ],
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentNode(Comment comment, int depth) {
    final isOwner = comment.userId == context.read<SocialService>().currentUserId;
    final commentUser = comment.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 24.0, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (commentUser != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SocialProfileScreen(userId: commentUser.id)));
                  }
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: commentUser?.avatarUrl != null ? NetworkImage(commentUser!.avatarUrl!) : null,
                  child: commentUser?.avatarUrl == null ? const Icon(Icons.person, size: 16) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                commentUser?.username ?? 'user',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              // Badge'ler
                              if (commentUser != null) ...[
                                if (commentUser.isSuperAdmin)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Text('👑', style: TextStyle(fontSize: 12)),
                                  )
                                else if (commentUser.isAdmin)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Text('🛡️', style: TextStyle(fontSize: 12)),
                                  ),
                                if (commentUser.isVerified)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 3),
                                    child: Icon(Icons.verified, size: 14, color: Colors.blue.shade400),
                                  ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(comment.content),
                        ],
                      ),
                    ),
                    // Aksiyon butonları
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 16,
                        children: [
                          Text(
                            DateFormat.yMMMd('tr_TR').add_Hm().format(comment.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _replyingTo = comment),
                            child: Text('Yanıtla', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          // Kendi yorumu → Sil
                          if (isOwner)
                            GestureDetector(
                              onTap: () => _confirmDeleteComment(comment.id),
                              child: Text('Sil', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          // Admin → Admin Sil
                          if (_isAdmin && !isOwner)
                            GestureDetector(
                              onTap: () => _confirmDeleteComment(comment.id, asAdmin: true),
                              child: Text('Admin Sil', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange, fontWeight: FontWeight.bold)),
                            ),
                          // Admin → Uyar
                          if (_isAdmin && !isOwner)
                            GestureDetector(
                              onTap: () => _showWarnDialog(comment.userId, commentUser?.username),
                              child: Text('Uyar', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                            ),
                          // Normal kullanıcı → Raporla
                          if (!isOwner && !_isAdmin)
                            GestureDetector(
                              onTap: () => _showReportCommentDialog(comment.id, comment.userId),
                              child: Text('Raporla', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (comment.replies.isNotEmpty)
          ...comment.replies.map((reply) => _buildCommentNode(reply, depth + 1)),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Muted uyarısı
          if (_isMuted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.volume_off, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Hesabınız susturulmuş durumda. Yorum yapamazsınız.', style: TextStyle(color: Colors.orange, fontSize: 13))),
                ],
              ),
            ),
          ],
          if (_replyingTo != null) ...[
            Row(
              children: [
                Expanded(child: Text('Yanıtlanıyor: @${_replyingTo!.user?.username ?? 'user'}', style: Theme.of(context).textTheme.bodySmall)),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _replyingTo = null),
                ),
              ],
            ),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  enabled: !_isMuted,
                  decoration: InputDecoration(
                    hintText: _isMuted ? 'Susturulmuş...' : 'Yorum ekle...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                color: _isMuted ? Colors.grey : Theme.of(context).colorScheme.primary,
                onPressed: _isMuted ? null : _submitComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
