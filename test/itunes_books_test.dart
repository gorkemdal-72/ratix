import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  test('Test iTunes Books API', () async {
    final query = 'altıncı koğuş';
    final url = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeQueryComponent(query)}&entity=ebook&limit=10');
    
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      
      debugPrint('Status: ${res.statusCode}');
      if (res.statusCode != 200) {
         debugPrint(res.body);
         return;
      }
      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List? ?? [];
      
      debugPrint('Found ${results.length} results');
      for (var item in results) {
        debugPrint('- ${item['trackName']} by ${item['artistName']} | Poster: ${item['artworkUrl100']}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  });
}
