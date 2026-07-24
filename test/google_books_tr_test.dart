import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  test('Test Google Books API directly', () async {
    final query = 'altıncı koğuş';
    final url = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeQueryComponent(query)}&maxResults=10&langRestrict=tr');
    
    try {
      final res = await http.get(url, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));
      
      debugPrint('Status: ${res.statusCode}');
      if (res.statusCode != 200) {
         debugPrint(res.body);
         return;
      }
      final data = json.decode(res.body) as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];
      
      debugPrint('Found ${items.length} results');
      for (var item in items) {
        final volInfo = item['volumeInfo'];
        debugPrint('- ${volInfo['title']} by ${(volInfo['authors'] as List?)?.join(', ')}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  });
}
