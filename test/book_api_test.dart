import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ratix/services/search_service.dart';
import 'package:ratix/models/category_type.dart';

void main() {
  test('Test Google Books API with query b', () async {
    final service = SearchService.instance;
    final results = await service.search(CategoryType.book, 'b');
    debugPrint('Found ${results.length} results');
    for (var r in results) {
      debugPrint('- ${r.title}');
    }
  });
}
