import 'rating_type.dart';
import 'category_type.dart';

class CategoryModel {
  final String id;
  final String name;
  final RatingType ratingType;
  final String icon;
  final CategoryType categoryType;
  final int itemCount;
  final DateTime? updatedAt;
  final bool isPrivate;
  final String? passwordHash;
  final String? parentId; // Alt kategori ise üst kategorinin ID'si
  final String? customStatus1;
  final String? customStatus2;
  final String? customStatus3;

  CategoryModel({
    required this.id,
    required this.name,
    required this.ratingType,
    this.icon = '📁',
    this.categoryType = CategoryType.custom,
    this.itemCount = 0,
    this.updatedAt,
    this.isPrivate = false,
    this.passwordHash,
    this.parentId,
    this.customStatus1,
    this.customStatus2,
    this.customStatus3,
  });

  bool get isSubCategory => parentId != null && parentId!.isNotEmpty;

  String get status1Label => (customStatus1 != null && customStatus1!.trim().isNotEmpty)
      ? customStatus1!.trim()
      : categoryType.status1Label;

  String? get status2Label => (customStatus2 != null && customStatus2!.trim().isNotEmpty)
      ? customStatus2!.trim()
      : categoryType.status2Label;

  String get status3Label => (customStatus3 != null && customStatus3!.trim().isNotEmpty)
      ? customStatus3!.trim()
      : categoryType.status3Label;

  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parsedUpdatedAt;
    if (map['updated_at'] != null) {
      parsedUpdatedAt = DateTime.tryParse(map['updated_at'].toString());
    } else if (map['created_at'] != null) {
      parsedUpdatedAt = DateTime.tryParse(map['created_at'].toString());
    }

    return CategoryModel(
      id: docId,
      name: map['name'] ?? '',
      ratingType: RatingType.values.firstWhere(
        (e) => e.name == map['ratingType'] || e.name == map['rating_type'],
        orElse: () => RatingType.stars5,
      ),
      icon: map['icon'] ?? '📁',
      categoryType: CategoryType.values.firstWhere(
        (e) => e.name == map['categoryType'] || e.name == map['category_type'],
        orElse: () => CategoryType.custom,
      ),
      itemCount: map['item_count'] ?? 0,
      updatedAt: parsedUpdatedAt,
      isPrivate: map['is_private'] ?? false,
      passwordHash: map['password_hash'],
      parentId: (map['parentId'] ?? map['parent_id']) as String?,
      customStatus1: (map['custom_status_1'] ?? map['customStatus1']) as String?,
      customStatus2: (map['custom_status_2'] ?? map['customStatus2']) as String?,
      customStatus3: (map['custom_status_3'] ?? map['customStatus3']) as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ratingType': ratingType.name,
      'icon': icon,
      'categoryType': categoryType.name,
      'item_count': itemCount,
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'is_private': isPrivate,
      'password_hash': passwordHash,
      if (parentId != null) 'parent_id': parentId,
      if (customStatus1 != null) 'custom_status_1': customStatus1,
      if (customStatus2 != null) 'custom_status_2': customStatus2,
      if (customStatus3 != null) 'custom_status_3': customStatus3,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    RatingType? ratingType,
    String? icon,
    CategoryType? categoryType,
    int? itemCount,
    DateTime? updatedAt,
    bool? isPrivate,
    String? passwordHash,
    String? parentId,
    String? customStatus1,
    String? customStatus2,
    String? customStatus3,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ratingType: ratingType ?? this.ratingType,
      icon: icon ?? this.icon,
      categoryType: categoryType ?? this.categoryType,
      itemCount: itemCount ?? this.itemCount,
      updatedAt: updatedAt ?? this.updatedAt,
      isPrivate: isPrivate ?? this.isPrivate,
      passwordHash: passwordHash ?? this.passwordHash,
      parentId: parentId ?? this.parentId,
      customStatus1: customStatus1 ?? this.customStatus1,
      customStatus2: customStatus2 ?? this.customStatus2,
      customStatus3: customStatus3 ?? this.customStatus3,
    );
  }
}