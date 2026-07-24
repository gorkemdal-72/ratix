import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  test('Test OpenLibrary API', () async {
    final query = 'harry potter';
    final q = Uri.encodeQueryComponent(query);
    final url = Uri.parse('https://openlibrary.org/search.json?q=$q&limit=10');

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        debugPrint('HTTP Error: ${res.statusCode}');
        return;
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      final docs = data['docs'] as List? ?? [];

      for (var doc in docs) {
        final title = doc['title'] as String? ?? '';
        final author = (doc['author_name'] as List?)?.join(', ');
        final year = doc['first_publish_year'] as int?;
        final coverId = doc['cover_i'];
        
        String? posterUrl;
        if (coverId != null) {
          posterUrl = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
        }
        
        debugPrint('- $title ($year) by $author | Poster: $posterUrl');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  });
}
