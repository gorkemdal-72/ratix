import 'package:flutter/material.dart';
import '../../services/search_service.dart';
import '../../models/category_type.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/watch_providers_widget.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _isLoading = true;
  List<SearchResult> _trendingMovies = [];
  List<SearchResult> _trendingTv = [];

  @override
  void initState() {
    super.initState();
    _fetchTrending();
  }

  Future<void> _fetchTrending() async {
    setState(() => _isLoading = true);
    try {
      final movies = await SearchService.instance.getTrending(mediaType: 'movie', timeWindow: 'day');
      final tv = await SearchService.instance.getTrending(mediaType: 'tv', timeWindow: 'day');
      if (mounted) {
        setState(() {
          _trendingMovies = movies;
          _trendingTv = tv;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showItemDetails(BuildContext context, SearchResult item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.posterUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: item.posterUrl!,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (item.year != null)
                        Text('${item.year}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      if (item.overview != null && item.overview!.isNotEmpty)
                        Text(
                          item.overview!,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Nereden İzlenir Bölümü
            WatchProvidersWidget(mediaType: item.mediaType ?? 'movie', externalId: item.externalId),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.isEn ? 'Close' : 'Kapat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection(String title, List<SearchResult> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => _showItemDetails(context, item),
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item.posterUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: item.posterUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                              : Container(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  child: const Icon(Icons.movie),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.isEn ? 'Discover' : 'Keşfet'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchTrending,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildTrendingSection(AppStrings.isEn ? 'Trending Movies' : 'Popüler Filmler', _trendingMovies),
                  const SizedBox(height: 24),
                  _buildTrendingSection(AppStrings.isEn ? 'Trending TV Shows' : 'Popüler Diziler', _trendingTv),
                ],
              ),
            ),
    );
  }
}
