import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final key = '5e841c860a6ffa0c68a49931c352d414'; 
  
  // Search for Bleach
  final searchUrl = Uri.parse('https://api.themoviedb.org/3/search/tv?api_key=$key&query=Bleach&language=tr-TR');
  final resSearch = await http.get(searchUrl);
  final searchData = json.decode(resSearch.body);
  final tvId = searchData['results'][0]['id'];
  print('Bleach ID: $tvId');

  // Get details
  final detailsUrl = Uri.parse('https://api.themoviedb.org/3/tv/$tvId?api_key=$key&language=tr-TR');
  final resDetails = await http.get(detailsUrl);
  final details = json.decode(resDetails.body);
  
  print('Next episode: ${details['next_episode_to_air']}');
  
  final seasonNum = details['seasons'].last['season_number'];
  print('Latest season: $seasonNum');

  // Get season
  final seasonUrl = Uri.parse('https://api.themoviedb.org/3/tv/$tvId/season/$seasonNum?api_key=$key&language=tr-TR');
  final resSeason = await http.get(seasonUrl);
  final seasonData = json.decode(resSeason.body);
  
  final episodes = seasonData['episodes'] as List;
  if (episodes.isNotEmpty) {
     print('Last episode: ${episodes.last['name']} - Air Date: ${episodes.last['air_date']}');
  }
}
