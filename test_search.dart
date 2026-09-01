import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final query = 'inauthor:\"Ýskender Pala\"';
  final params = {
    'q': query,
    'maxResults': '5',
  };
  final url = Uri.https('www.googleapis.com', '/books/v1/volumes', params);
  final res = await http.get(url);
  if (res.statusCode == 200) {
    final data = json.decode(res.body);
    final items = data['items'] ?? [];
    for (var item in items) {
      print(item['volumeInfo']['title']);
    }
  } else {
    print('Hata: \');
  }
}
