import 'package:supabase/supabase.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final client = SupabaseClient('https://mebuwgyvsezzaruclnab.supabase.co', 'sb_publishable_7Qv6KNh9AyjRe9lNOGHgWA_R1h0S_yu');
  final key = '5e841c860a6ffa0c68a49931c352d414';
  
  final now = DateTime.now().toIso8601String();
  final res = await client
      .from('items')
      .select('id, title, external_id, next_air_date')
      .eq('media_type', 'tv')
      .or('next_air_date.is.null,next_air_date.lt.$now');
      
  print('Found ${res.length} items to sync.');
  
  for(var row in res) {
      final title = row['title'];
      final ext = row['external_id'];
      if(title == 'BLEACH') {
          print('Syncing BLEACH...');
          final detailsUrl = Uri.parse('https://api.themoviedb.org/3/tv/$ext?api_key=$key&language=tr-TR');
          final r = await http.get(detailsUrl);
          final data = json.decode(r.body);
          
          if(data['next_episode_to_air'] != null) {
              final airDate = data['next_episode_to_air']['air_date'];
              print('BLEACH next_episode_to_air: $airDate');
              
              await client.from('items').update({'next_air_date': airDate}).eq('id', row['id']);
              print('Updated Supabase successfully.');
          } else {
              print('BLEACH has no next_episode_to_air');
          }
      }
  }
}
