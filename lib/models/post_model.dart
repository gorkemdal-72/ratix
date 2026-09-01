import 'user_model.dart';
import 'item_model.dart';

class Post {
  final String id;
  final String userId;
  final String? itemId;
  final String? content;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isSpoiler; // YENİ: Spoiler Kalkanı
  
  // Relations
  final UserModel? user;
  final ItemModel? item;
  final int commentCount;
  final bool isEditorsChoice;
  final String visibility; // 'public' veya 'followers_only'
  
  // YENİ: Reaksiyon Sistemi
  final Map<String, int> reactionCounts; // Örn: {'like': 5, 'haha': 2}
  final String? myReaction; // Benim yaptığım reaksiyon (null ise yapmadım)

  Post({
    required this.id,
    required this.userId,
    this.itemId,
    this.content,
    this.imageUrl,
    required this.createdAt,
    this.isSpoiler = false,
    this.user,
    this.item,
    this.commentCount = 0,
    this.isEditorsChoice = false,
    this.visibility = 'public',
    this.reactionCounts = const {},
    this.myReaction,
  });

  factory Post.fromJson(Map<String, dynamic> json, {String? myReaction}) {
    DateTime parsedDate = DateTime.now();
    try {
      if (json['created_at'] != null) {
        parsedDate = DateTime.parse(json['created_at'].toString()).toLocal();
      }
    } catch (_) {}

    // Reaksiyonları hesapla
    Map<String, int> rCounts = {};
    if (json['post_likes'] is List) {
      final likes = json['post_likes'] as List;
      for (var l in likes) {
        if (l is Map && l['reaction_type'] != null) {
          final rType = l['reaction_type'].toString();
          rCounts[rType] = (rCounts[rType] ?? 0) + 1;
        } else {
          rCounts['like'] = (rCounts['like'] ?? 0) + 1;
        }
      }
    }

    return Post(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      itemId: json['item_id'] as String?,
      content: json['content'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: parsedDate,
      isSpoiler: json['is_spoiler'] == true,
      user: json['users'] != null ? UserModel.fromJson(json['users']) : null,
      item: json['items'] != null ? ItemModel.fromMap(json['items'], json['items']['id'] ?? '') : null,
      commentCount: json['comments'] is List ? (json['comments'] as List).length : (json['comment_count'] is num ? (json['comment_count'] as num).toInt() : 0),
      isEditorsChoice: json['is_editors_choice'] == true,
      visibility: json['visibility'] as String? ?? 'public',
      reactionCounts: rCounts,
      myReaction: myReaction,
    );
  }

  Post copyWith({
    bool? isSpoiler,
    int? commentCount,
    bool? isEditorsChoice,
    String? visibility,
    Map<String, int>? reactionCounts,
    String? myReaction,
  }) {
    return Post(
      id: id,
      userId: userId,
      itemId: itemId,
      content: content,
      imageUrl: imageUrl,
      createdAt: createdAt,
      isSpoiler: isSpoiler ?? this.isSpoiler,
      user: user,
      item: item,
      commentCount: commentCount ?? this.commentCount,
      isEditorsChoice: isEditorsChoice ?? this.isEditorsChoice,
      visibility: visibility ?? this.visibility,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      myReaction: myReaction ?? this.myReaction,
    );
  }
}
