import 'user_model.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String? parentId;
  final String content;
  final DateTime createdAt;

  // Relations
  final UserModel? user;
  final int likeCount;
  final bool isLikedByMe;
  final List<Comment> replies; // nested replies
  
  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentId,
    required this.content,
    required this.createdAt,
    this.user,
    this.likeCount = 0,
    this.isLikedByMe = false,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json, {bool isLiked = false}) {
    DateTime parsedDate = DateTime.now();
    try {
      if (json['created_at'] != null) {
        parsedDate = DateTime.parse(json['created_at'].toString());
      }
    } catch (_) {}

    return Comment(
      id: json['id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: parsedDate,
      user: json['users'] != null ? UserModel.fromJson(json['users']) : null,
      likeCount: json['comment_likes'] is List ? (json['comment_likes'] as List).length : (json['like_count'] is num ? (json['like_count'] as num).toInt() : 0),
      isLikedByMe: isLiked,
      replies: [], // Will be populated manually or recursively
    );
  }

  Comment copyWith({List<Comment>? replies, bool? isLikedByMe, int? likeCount}) {
    return Comment(
      id: id,
      postId: postId,
      userId: userId,
      parentId: parentId,
      content: content,
      createdAt: createdAt,
      user: user,
      likeCount: likeCount ?? this.likeCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      replies: replies ?? this.replies,
    );
  }
}
