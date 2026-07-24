class UserModel {
  final String id;
  final String? email;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final String? badgeEmoji;
  final String? fcmToken;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final String diaryVisibility;

  // ─── Admin & Moderasyon Alanları ───
  final bool isAdmin;
  final bool isVerified;
  final bool isBanned;
  final DateTime? mutedUntil;
  final String? muteReason;
  final bool isShadowbanned;

  UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.bio,
    this.badgeEmoji,
    this.fcmToken,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.diaryVisibility = 'followers_only',
    this.isAdmin = false,
    this.isVerified = false,
    this.isBanned = false,
    this.mutedUntil,
    this.muteReason,
    this.isShadowbanned = false,
  });

  /// zodleenar = platform kurucusu / süper admin
  bool get isSuperAdmin => username == 'zodleenar';

  /// Kullanıcı şu an susturulmuş mu?
  bool get isMuted =>
      mutedUntil != null && mutedUntil!.isAfter(DateTime.now());

  /// Admin VEYA süper admin mi?
  bool get hasAdminPrivileges => isAdmin || isSuperAdmin;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // muted_until parse
    DateTime? parsedMutedUntil;
    try {
      if (json['muted_until'] != null) {
        parsedMutedUntil = DateTime.parse(json['muted_until'].toString());
      }
    } catch (_) {}

    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      badgeEmoji: json['badge_emoji'] as String?,
      fcmToken: json['fcm_token'] as String?,
      followersCount: json['followers_count'] is num
          ? (json['followers_count'] as num).toInt()
          : 0,
      followingCount: json['following_count'] is num
          ? (json['following_count'] as num).toInt()
          : 0,
      postsCount: json['posts_count'] is num
          ? (json['posts_count'] as num).toInt()
          : 0,
      diaryVisibility: json['diary_visibility'] as String? ?? 'followers_only',
      isAdmin: json['is_admin'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      isBanned: json['is_banned'] as bool? ?? false,
      mutedUntil: parsedMutedUntil,
      muteReason: json['mute_reason'] as String?,
      isShadowbanned: json['is_shadowbanned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'username': username,
      'avatar_url': avatarUrl,
      'bio': bio,
      'badge_emoji': badgeEmoji,
      'diary_visibility': diaryVisibility,
    };
  }
}
