import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';

class SocialService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ─── FOLLOWS & BLOCKS ───

  Future<void> followUser(String targetUserId) async {
    if (currentUserId == null) return;
    await _supabase.from('follows').insert({
      'follower_id': currentUserId,
      'following_id': targetUserId,
    });
    await _sendNotification(targetUserId, 'follow', null, null);
  }

  Future<void> unfollowUser(String targetUserId) async {
    if (currentUserId == null) return;
    await _supabase.from('follows')
      .delete()
      .match({'follower_id': currentUserId!, 'following_id': targetUserId});
  }

  Future<bool> isFollowing(String targetUserId) async {
    if (currentUserId == null) return false;
    final res = await _supabase.from('follows')
      .select('follower_id')
      .match({'follower_id': currentUserId!, 'following_id': targetUserId})
      .maybeSingle();
    return res != null;
  }

  Future<List<UserModel>> getFollowers(String userId) async {
    final res = await _supabase.from('follows')
        .select('users!follows_follower_id_fkey(*)')
        .eq('following_id', userId);
    return (res as List).map((item) => UserModel.fromJson(item['users'] as Map<String, dynamic>)).toList();
  }

  Future<List<UserModel>> getFollowing(String userId) async {
    final res = await _supabase.from('follows')
        .select('users!follows_following_id_fkey(*)')
        .eq('follower_id', userId);
    return (res as List).map((item) => UserModel.fromJson(item['users'] as Map<String, dynamic>)).toList();
  }

  Future<Set<String>> getFollowingIds(String userId) async {
    final res = await _supabase.from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    return (res as List).map((f) => f['following_id'] as String).toSet();
  }

  // ─── BLOCKS ───

  Future<void> blockUser(String targetUserId) async {
    if (currentUserId == null) return;
    // First unfollow if following
    try { await unfollowUser(targetUserId); } catch (_) {}
    // Remove their follow too
    try {
      await _supabase.from('follows').delete().match({'follower_id': targetUserId, 'following_id': currentUserId!});
    } catch (_) {}
    // Block
    await _supabase.from('blocks').insert({
      'blocker_id': currentUserId,
      'blocked_id': targetUserId,
    });
  }

  Future<void> unblockUser(String targetUserId) async {
    if (currentUserId == null) return;
    await _supabase.from('blocks').delete().match({'blocker_id': currentUserId!, 'blocked_id': targetUserId});
  }

  Future<bool> isBlocked(String targetUserId) async {
    if (currentUserId == null) return false;
    final res = await _supabase.from('blocks')
      .select('blocker_id')
      .match({'blocker_id': currentUserId!, 'blocked_id': targetUserId})
      .maybeSingle();
    return res != null;
  }

  Future<bool> isBlockedBy(String targetUserId) async {
    if (currentUserId == null) return false;
    final res = await _supabase.from('blocks')
      .select('blocker_id')
      .match({'blocker_id': targetUserId, 'blocked_id': currentUserId!})
      .maybeSingle();
    return res != null;
  }

  Future<List<UserModel>> getBlockedUsers() async {
    if (currentUserId == null) return [];
    final res = await _supabase.from('blocks')
      .select('users!blocks_blocked_id_fkey(*)')
      .eq('blocker_id', currentUserId!);
    return (res as List).map((item) => UserModel.fromJson(item['users'] as Map<String, dynamic>)).toList();
  }

  // ─── POSTS ───

  Future<void> createPost({String? content, String? itemId, String? imageUrl, String visibility = 'public'}) async {
    if (currentUserId == null) return;
    await _supabase.from('posts').insert({
      'user_id': currentUserId,
      if (itemId != null) 'item_id': itemId,
      if (content != null && content.isNotEmpty) 'content': content,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      'visibility': visibility,
    });
  }

  // Timeline: Sadece takip edilenler ve kendi gönderilerin
  Future<List<Post>> getTimeline({int limit = 20, int offset = 0}) async {
    if (currentUserId == null) return [];
    
    final follows = await _supabase.from('follows')
        .select('following_id')
        .eq('follower_id', currentUserId!);
    
    List<String> userIds = [currentUserId!];
    for (var f in follows) {
      userIds.add(f['following_id'] as String);
    }

    final res = await _supabase.from('posts')
        .select('*, users!posts_user_id_fkey(*), items(*), post_likes(user_id, reaction_type), comments(id)')
        .inFilter('user_id', userIds)
        .order('created_at', ascending: false)
        .range(offset, offset + limit * 2);

    return _parsePosts(res)
        .where((p) => _canSeePost(p))
        .where((p) => p.userId == currentUserId || p.user?.diaryVisibility != 'private')
        .take(limit)
        .toList();
  }

  // Discover: Sadece herkese açık (public) gönderiler
  Future<List<Post>> getDiscoverPosts({int limit = 20, int offset = 0}) async {
    final res = await _supabase.from('posts')
        .select('*, users!posts_user_id_fkey(*), items(*), post_likes(user_id, reaction_type), comments(id)')
        .eq('visibility', 'public')
        .order('is_editors_choice', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit * 2);

    return _parsePosts(res)
        .where((p) => _canSeePost(p))
        .where((p) => p.userId == currentUserId || (p.user?.diaryVisibility != 'private' && p.user?.diaryVisibility != 'followers_only'))
        .take(limit)
        .toList();
  }

  Future<List<Post>> getUserPosts(String userId, {int limit = 20, int offset = 0}) async {
    final res = await _supabase.from('posts')
        .select('*, users!posts_user_id_fkey(*), items(*), post_likes(user_id, reaction_type), comments(id)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return _parsePosts(res); // Kullanıcının kendi profilinde filtrelemeye gerek yok (kendi görsün)
  }

  Future<void> deletePost(String postId) async {
    if (currentUserId == null) return;
    await _supabase.from('posts').delete().match({'id': postId, 'user_id': currentUserId!});
  }

  Future<Post?> getPostById(String postId) async {
    final res = await _supabase.from('posts')
        .select('*, users!posts_user_id_fkey(*), items(*), post_likes(user_id, reaction_type), comments(id)')
        .eq('id', postId)
        .maybeSingle();
    
    if (res == null) return null;
    final post = _parsePosts([res]).first;
    return _canSeePost(post) ? post : null;
  }

  bool _canSeePost(Post post) {
    // Shadowban mantığı: Gönderi sahibi shadowban yemişse ve görüntüleyen kişi O değilse, gizle.
    if (post.user?.isShadowbanned == true && post.userId != currentUserId) {
      return false;
    }
    return true;
  }

  List<Post> _parsePosts(List<dynamic> data) {
    return data.map((json) {
      String? myReaction;
      if (currentUserId != null && json['post_likes'] != null) {
        final likes = json['post_likes'] as List;
        for (var like in likes) {
          if (like is Map && like['user_id'] == currentUserId) {
            myReaction = like['reaction_type']?.toString() ?? 'like';
            break;
          }
        }
      }
      return Post.fromJson(json, myReaction: myReaction);
    }).toList();
  }

  // ─── LIKES ───

  Future<void> setPostReaction(String postId, String postOwnerId, String? reactionType) async {
    if (currentUserId == null) return;
    try {
      if (reactionType == null) {
        // Reaksiyonu kaldır
        await _supabase.from('post_likes')
            .delete()
            .match({'user_id': currentUserId!, 'post_id': postId});
      } else {
        // Yeni reaksiyon ekle veya güncelle (Upsert)
        await _supabase.from('post_likes').upsert({
          'user_id': currentUserId,
          'post_id': postId,
          'reaction_type': reactionType,
        }, onConflict: 'user_id, post_id'); // Note: Make sure there's a unique constraint on (user_id, post_id)
        
        if (postOwnerId != currentUserId) {
          await _sendNotification(postOwnerId, 'post_reaction', postId, null);
        }
      }
    } catch (_) {}
  }

  Future<void> toggleCommentLike(String commentId, String commentOwnerId, bool isLiked) async {
    if (currentUserId == null) return;
    try {
      if (isLiked) {
        await _supabase.from('comment_likes')
            .delete()
            .match({'user_id': currentUserId!, 'comment_id': commentId});
      } else {
        await _supabase.from('comment_likes').insert({
          'user_id': currentUserId,
          'comment_id': commentId,
        });
        if (commentOwnerId != currentUserId) {
          await _sendNotification(commentOwnerId, 'comment_like', null, commentId);
        }
      }
    } catch (_) {}
  }

  // ─── COMMENTS ───

  Future<List<Comment>> getComments(String postId) async {
    final res = await _supabase.from('comments')
        .select('*, users!comments_user_id_fkey(*), comment_likes(user_id)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    List<Comment> allComments = res.map((json) {
      bool isLiked = false;
      if (currentUserId != null && json['comment_likes'] != null) {
        final likes = json['comment_likes'] as List;
        isLiked = likes.any((like) => like['user_id'] == currentUserId);
      }
      return Comment.fromJson(json, isLiked: isLiked);
    }).where((c) {
      if (c.user?.isShadowbanned == true && c.userId != currentUserId) return false;
      return true;
    }).toList();

    List<Comment> parentComments = allComments.where((c) => c.parentId == null).toList();
    for (var parent in parentComments) {
      parent.replies.addAll(allComments.where((c) => c.parentId == parent.id).toList());
    }
    
    return parentComments;
  }

  Future<void> addComment({required String postId, required String postOwnerId, required String content, String? parentId, String? parentOwnerId}) async {
    if (currentUserId == null) return;
    final res = await _supabase.from('comments').insert({
      'post_id': postId,
      'user_id': currentUserId,
      if (parentId != null) 'parent_id': parentId,
      'content': content,
    }).select().single();
    
    final insertedCommentId = res['id'] as String;

    if (parentId != null && parentOwnerId != null && parentOwnerId != currentUserId) {
      await _sendNotification(parentOwnerId, 'reply', postId, insertedCommentId);
    } else if (postOwnerId != currentUserId) {
      await _sendNotification(postOwnerId, 'comment', postId, insertedCommentId);
    }
  }

  Future<void> deleteComment(String commentId) async {
    if (currentUserId == null) return;
    await _supabase.from('comments').delete().match({'id': commentId, 'user_id': currentUserId!});
  }

  // ─── USER PROFILE ───

  Future<UserModel?> getUserProfile(String userId) async {
    final res = await _supabase.from('user_social_profiles_view')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (res != null) {
      return UserModel.fromJson(res);
    }
    return null;
  }

  // ─── NOTIFICATIONS ───
  Future<void> _sendNotification(String recipientId, String type, String? postId, String? commentId) async {
    if (currentUserId == null || currentUserId == recipientId) return;
    try {
      // Spam engeli süresi belirle
      int cooldownMinutes = 0;
      if (type == 'follow') {
        cooldownMinutes = 24 * 60; // 24 saat
      } else if (type == 'post_like' || type == 'comment_like') {
        cooldownMinutes = -1; // Süre sınırı yok, aynı gönderiye sadece 1 kere bildirim gider
      } else if (type == 'comment' || type == 'reply') {
        cooldownMinutes = 1; // 1 dakika
      }

      var query = _supabase.from('notifications')
          .select('id')
          .eq('recipient_id', recipientId)
          .eq('sender_id', currentUserId!)
          .eq('type', type);
          
      if (postId != null) query = query.eq('post_id', postId);
      if (commentId != null) query = query.eq('comment_id', commentId);

      if (cooldownMinutes > 0) {
        final timeAgo = DateTime.now().toUtc().subtract(Duration(minutes: cooldownMinutes)).toIso8601String();
        query = query.gte('created_at', timeAgo);
      }

      final res = await query.limit(1).maybeSingle();
      if (res != null) return; // Spam koruması: Zaten bildirim atılmış

      await _supabase.from('notifications').insert({
        'recipient_id': recipientId,
        'sender_id': currentUserId,
        'type': type,
        if (postId != null) 'post_id': postId,
        if (commentId != null) 'comment_id': commentId,
      });
    } catch (_) {}
  }
}
