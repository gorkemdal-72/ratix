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
  });

  bool get isSubCategory => parentId != null && parentId!.isNotEmpty;

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
    );
  }
}