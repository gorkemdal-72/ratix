import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import 'package:intl/intl.dart';
import 'social_profile_screen.dart';
import 'post_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<NotificationService>();
      final notifs = await service.getNotifications();
      if (mounted) setState(() => _notifications = notifs);
      
      await service.markAllAsRead();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('Bildiriminiz bulunmuyor.'))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final sender = n.sender;
                      
                      String text = '';
                      IconData icon = Icons.notifications;
                      Color iconColor = Colors.grey;

                      switch (n.type) {
                        case 'follow':
                          text = 'seni takip etmeye başladı.';
                          icon = Icons.person_add;
                          iconColor = Colors.blue;
                          break;
                        case 'post_like':
                          text = n.postItemTitle != null ? "'${n.postItemTitle}' paylaşımını beğendi." : 'gönderini beğendi.';
                          icon = Icons.favorite;
                          iconColor = Colors.red;
                          break;
                        case 'comment_like':
                          final cPreview = n.commentContent != null ? "'${n.commentContent!.length > 30 ? '${n.commentContent!.substring(0, 30)}...' : n.commentContent}' " : '';
                          text = '${cPreview}yorumunu beğendi.';
                          icon = Icons.favorite;
                          iconColor = Colors.red;
                          break;
                        case 'comment':
                          text = n.postItemTitle != null ? "'${n.postItemTitle}' paylaşımına yorum yaptı." : 'gönderine yorum yaptı.';
                          icon = Icons.comment;
                          iconColor = Colors.green;
                          break;
                        case 'reply':
                          final cPreview2 = n.commentContent != null ? "'${n.commentContent!.length > 30 ? '${n.commentContent!.substring(0, 30)}...' : n.commentContent}' " : '';
                          text = '${cPreview2}yorumuna yanıt verdi.';
                          icon = Icons.reply;
                          iconColor = Colors.orange;
                          break;
                        case 'warning':
                          text = 'sana bir uyarı gönderdi.';
                          icon = Icons.warning_amber_rounded;
                          iconColor = Colors.orange;
                          break;
                        case 'admin_grant':
                          text = 'seni admin yaptı.';
                          icon = Icons.shield;
                          iconColor = Colors.blue;
                          break;
                        case 'admin_revoke':
                          text = 'admin yetkilerini aldı.';
                          icon = Icons.remove_moderator;
                          iconColor = Colors.red;
                          break;
                        case 'mute':
                          text = 'seni belirli bir süreliğine susturdu.';
                          icon = Icons.volume_off;
                          iconColor = Colors.redAccent;
                          break;
                        case 'ban':
                          text = 'hesabını kalıcı olarak yasakladı.';
                          icon = Icons.block;
                          iconColor = Colors.red;
                          break;
                        case 'report_resolved':
                          text = 'şikayetini inceledi ve gerekli aksiyonu aldı. Teşekkürler!';
                          icon = Icons.check_circle;
                          iconColor = Colors.green;
                          break;
                        case 'report_dismissed':
                          text = 'şikayetini inceledi ancak ihlal tespit etmedi.';
                          icon = Icons.info_outline;
                          iconColor = Colors.grey;
                          break;
                        case 'system':
                          text = 'sana bir sistem mesajı gönderdi.';
                          icon = Icons.campaign;
                          iconColor = Colors.blueAccent;
                          break;
                        case 'new_report':
                          text = 'yeni bir şikayet oluşturdu (Admin Bildirimi).';
                          icon = Icons.report_problem;
                          iconColor = Colors.orange;
                          break;
                      }

                      Widget? subtitleWidget;
                      if (n.type == 'comment' || n.type == 'reply') {
                        final previewContent = n.commentContent ?? '';
                        if (previewContent.isNotEmpty) {
                          subtitleWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '"$previewContent"',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).textTheme.bodyMedium?.color),
                              ),
                              const SizedBox(height: 4),
                              Text(DateFormat.yMMMd('tr_TR').add_Hm().format(n.createdAt)),
                            ],
                          );
                        }
                      }
                      
                      subtitleWidget ??= Text(DateFormat.yMMMd('tr_TR').add_Hm().format(n.createdAt));

                       return ListTile(
                        leading: GestureDetector(
                          onTap: () {
                            if (sender != null) {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => SocialProfileScreen(userId: sender.id),
                              ));
                            }
                          },
                          child: CircleAvatar(
                            backgroundImage: sender?.avatarUrl != null ? NetworkImage(sender!.avatarUrl!) : null,
                            child: sender?.avatarUrl == null ? const Icon(Icons.person) : null,
                          ),
                        ),
                        title: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: sender?.displayName ?? 'Birisi', style: const TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: ' $text'),
                            ],
                          ),
                        ),
                        subtitle: subtitleWidget,
                        trailing: Icon(icon, color: iconColor),
                        tileColor: n.isRead ? null : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                        onTap: () {
                          if (n.type == 'follow') {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => SocialProfileScreen(userId: n.senderId),
                            ));
                          } else if (n.postId != null) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => PostDetailScreen(postId: n.postId),
                            ));
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
