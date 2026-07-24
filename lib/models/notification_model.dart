import 'user_model.dart';

class NotificationModel {
  final String id;
  final String recipientId;
  final String senderId;
  final String type; // follow, post_like, comment_like, comment, reply
  final String? postId;
  final String? commentId;
  final bool isRead;
  final DateTime createdAt;

  // Extra relations from joins
  final String? postItemTitle;
  final String? commentContent;
  final String? postContent;

  // Relations
  final UserModel? sender;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.type,
    this.postId,
    this.commentId,
    required this.isRead,
    required this.createdAt,
    this.postItemTitle,
    this.commentContent,
    this.postContent,
    this.sender,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    try {
      if (json['created_at'] != null) {
        parsedDate = DateTime.parse(json['created_at'].toString()).toLocal();
      }
    } catch (_) {}

    return NotificationModel(
      id: json['id'] as String? ?? '',
      recipientId: json['recipient_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      type: json['type'] as String? ?? 'follow',
      postId: json['post_id'] as String?,
      commentId: json['comment_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: parsedDate,
      postItemTitle: json['posts']?['items']?['title'] as String?,
      commentContent: json['comments']?['content'] as String?,
      postContent: json['posts']?['content'] as String?,
      sender: json['users'] != null ? UserModel.fromJson(json['users']) : null,
    );
  }
}
