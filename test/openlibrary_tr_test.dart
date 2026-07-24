import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  test('Test OpenLibrary with Turkish', () async {
    final query = 'altıncı koğuş';
    final q = Uri.encodeQueryComponent(query);
    final url = Uri.parse('https://openlibrary.org/search.json?q=$q&limit=10');

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      final data = json.decode(res.body) as Map<String, dynamic>;
      final docs = data['docs'] as List? ?? [];
      
      debugPrint('Found ${docs.length} results for $query');
      for (var doc in docs) {
        debugPrint('- ${doc['title']} by ${(doc['author_name'] as List?)?.join(', ')}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  });
}
