import 'rating_type.dart';
import 'category_type.dart';

class CategoryModel {
  final String id;
  final String name;
  final RatingType ratingType;
  final String icon;
  final CategoryType categoryType;

  CategoryModel({
    required this.id,
    required this.name,
    required this.ratingType,
    this.icon = '📁',
    this.categoryType = CategoryType.custom,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return CategoryModel(
      id: docId,
      name: map['name'] ?? '',
      // Enum dönüşümü (Eski veriler bozulmasın diye kontrol ekledik)
      ratingType: RatingType.values.firstWhere(
        (e) => e.name == map['ratingType'],
        orElse: () => RatingType.stars5,
      ),
      icon: map['icon'] ?? '📁',
      // Eski veriler 'custom' olarak fallback alır
      categoryType: CategoryType.values.firstWhere(
        (e) => e.name == map['categoryType'],
        orElse: () => CategoryType.custom,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ratingType': ratingType.name,
      'icon': icon,
      'categoryType': categoryType.name,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}