import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient('https://mebuwgyvsezzaruclnab.supabase.co', 'sb_publishable_7Qv6KNh9AyjRe9lNOGHgWA_R1h0S_yu');
  
  // Try to find TV shows
  final now = DateTime.now().toIso8601String();
  try {
      final res = await client
          .from('items')
          .select('id, title, external_id, next_air_date')
          .eq('media_type', 'tv')
          .or('next_air_date.is.null,next_air_date.lt.$now');
      print('Found items to sync: ${res.length}');
      for(var r in res) {
         print('${r['title']} - external_id: ${r['external_id']} - next_air_date: ${r['next_air_date']}');
      }
  } catch (e) {
      print('Error querying items: $e');
  }
}
