import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../core/app_strings.dart';
import '../../models/item_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;

  int _totalMinutes = 0;
  int _totalItems = 0;
  Map<String, int> _itemsByType = {};
  Map<String, int> _genresCount = {};

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final res = await _supabase
          .from('items')
          .select()
          .eq('user_id', userId);

      final items = (res as List).map((e) => ItemModel.fromMap(e, e['id'])).toList();
      
      int totalMin = 0;
      Map<String, int> typeCount = {};
      Map<String, int> genreCount = {};

      for (var item in items) {
        // Süre hesaplama
        if (item.runtime != null && item.watchStatus == 'watched') {
          totalMin += item.runtime!;
        } else if (item.runtime != null && item.watchStatus == 'watching' && item.seasonsData != null) {
          // Kısmi izleme süresi
          final selectedEps = item.selectedEpisodesCount;
          final totalEps = item.totalEpisodesCount;
          if (totalEps > 0 && selectedEps > 0) {
             double ratio = selectedEps / totalEps;
             totalMin += (item.runtime! * ratio).round();
          }
        }

        // Tür bazlı dağılım (Sadece film/dizi ve kitaplar için mantıklı)
        final type = item.mediaType ?? 'custom';
        typeCount[type] = (typeCount[type] ?? 0) + 1;

        // Genre sayımı
        for (var genre in item.genres) {
          if (genre.trim().isNotEmpty) {
            genreCount[genre] = (genreCount[genre] ?? 0) + 1;
          }
        }
      }

      // En çok izlenen türleri sırala (Top 5)
      var sortedGenres = genreCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      Map<String, int> topGenres = {};
      for (var i = 0; i < sortedGenres.length && i < 6; i++) {
        topGenres[sortedGenres[i].key] = sortedGenres[i].value;
      }

      setState(() {
        _totalItems = items.length;
        _totalMinutes = totalMin;
        _itemsByType = typeCount;
        _genresCount = topGenres;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Stat error: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDuration(int totalMinutes) {
    if (totalMinutes == 0) return AppStrings.isEn ? "No watch time" : "İzleme süresi yok";

    final months = totalMinutes ~/ (60 * 24 * 30);
    int rem = totalMinutes % (60 * 24 * 30);
    final days = rem ~/ (60 * 24);
    rem = rem % (60 * 24);
    final hours = rem ~/ 60;
    final minutes = rem % 60;

    List<String> parts = [];
    if (months > 0) parts.add(AppStrings.isEn ? "$months Month(s)" : "$months Ay");
    if (days > 0) parts.add(AppStrings.isEn ? "$days Day(s)" : "$days Gün");
    if (hours > 0) parts.add(AppStrings.isEn ? "$hours Hour(s)" : "$hours Saat");
    if (minutes > 0 && months == 0) parts.add(AppStrings.isEn ? "$minutes Min" : "$minutes Dk");

    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.isEn ? 'My Statistics' : 'İstatistiklerim'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOPLAM SÜRE KARTI
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spaceLg),
                  decoration: BoxDecoration(
                    gradient: isDark ? AppTheme.headerGradient : AppTheme.headerGradientLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : AppTheme.gradientStart).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.white.withOpacity(0.9), size: 32),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.isEn ? 'Total Time Spent' : 'Toplam Harcanan Süre',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_totalMinutes),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppTheme.spaceXl),
                
                // İÇERİK ÖZETİ
                Text(
                  AppStrings.isEn ? 'Content Overview' : 'İçerik Özeti',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppTheme.spaceMd),
                Row(
                  children: [
                    _buildStatCard(
                      AppStrings.isEn ? 'Total Items' : 'Toplam Kayıt', 
                      _totalItems.toString(), 
                      Icons.storage_rounded
                    ),
                    const SizedBox(width: AppTheme.spaceMd),
                    _buildStatCard(
                      AppStrings.isEn ? 'Movies' : 'Filmler', 
                      (_itemsByType['movie'] ?? 0).toString(), 
                      Icons.movie_creation_outlined
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMd),
                Row(
                  children: [
                    _buildStatCard(
                      AppStrings.isEn ? 'TV Shows' : 'Diziler', 
                      (_itemsByType['tv'] ?? 0).toString(), 
                      Icons.tv_outlined
                    ),
                    const SizedBox(width: AppTheme.spaceMd),
                    _buildStatCard(
                      AppStrings.isEn ? 'Books' : 'Kitaplar', 
                      (_itemsByType['book'] ?? 0).toString(), 
                      Icons.book_outlined
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spaceXl),

                // TÜR DAĞILIMI
                if (_genresCount.isNotEmpty) ...[
                  Text(
                    AppStrings.isEn ? 'Top Genres' : 'Favori Türler',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  SizedBox(
                    height: 250,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            sections: _getPieSections(),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Top ${_genresCount.length}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              AppStrings.isEn ? 'Genres' : 'Tür',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  _buildLegend(),
                  const SizedBox(height: AppTheme.spaceXl),
                ]
              ],
            ),
          ),
    );
  }

  Expanded _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  final List<Color> _chartColors = [
    AppTheme.primary,
    AppTheme.secondary,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.redAccent,
  ];

  List<PieChartSectionData> _getPieSections() {
    int i = 0;
    return _genresCount.entries.map((entry) {
      final color = _chartColors[i % _chartColors.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    int i = 0;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: _genresCount.entries.map((entry) {
        final color = _chartColors[i % _chartColors.length];
        i++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(entry.key, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}