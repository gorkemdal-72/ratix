import 'user_model.dart';
import 'item_model.dart';

class Post {
  final String id;
  final String userId;
  final String? itemId;
  final String? content;
  final String? imageUrl;
  final DateTime createdAt;
  
  // Relations
  final UserModel? user;
  final ItemModel? item;
  final int likeCount;
  final int commentCount;
  final bool isLikedByMe;
  final bool isEditorsChoice; // ADDED
  final String visibility; // 'public' veya 'followers_only'

  Post({
    required this.id,
    required this.userId,
    this.itemId,
    this.content,
    this.imageUrl,
    required this.createdAt,
    this.user,
    this.item,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByMe = false,
    this.isEditorsChoice = false, // ADDED
    this.visibility = 'public',
  });

  factory Post.fromJson(Map<String, dynamic> json, {bool isLiked = false}) {
    DateTime parsedDate = DateTime.now();
    try {
      if (json['created_at'] != null) {
        parsedDate = DateTime.parse(json['created_at'].toString()).toLocal();
      }
    } catch (_) {}

    return Post(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      itemId: json['item_id'] as String?,
      content: json['content'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: parsedDate,
      user: json['users'] != null ? UserModel.fromJson(json['users']) : null,
      item: json['items'] != null ? ItemModel.fromMap(json['items'], json['items']['id'] ?? '') : null,
      likeCount: json['post_likes'] is List ? (json['post_likes'] as List).length : (json['like_count'] is num ? (json['like_count'] as num).toInt() : 0),
      commentCount: json['comments'] is List ? (json['comments'] as List).length : (json['comment_count'] is num ? (json['comment_count'] as num).toInt() : 0),
      isLikedByMe: isLiked,
      isEditorsChoice: json['is_editors_choice'] == true, // ADDED
      visibility: json['visibility'] as String? ?? 'public',
    );
  }

  Post copyWith({
    int? likeCount,
    int? commentCount,
    bool? isLikedByMe,
    bool? isEditorsChoice, // ADDED
    String? visibility,
  }) {
    return Post(
      id: id,
      userId: userId,
      itemId: itemId,
      content: content,
      imageUrl: imageUrl,
      createdAt: createdAt,
      user: user,
      item: item,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isEditorsChoice: isEditorsChoice ?? this.isEditorsChoice, // ADDED
      visibility: visibility ?? this.visibility,
    );
  }
}
