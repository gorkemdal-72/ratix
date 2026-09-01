import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';
import '../../core/app_strings.dart';
import '../../models/item_model.dart';
import '../../models/category_type.dart';

// --- ROZET MODELİ ---
class UserBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int requiredCount;
  final int currentCount;

  UserBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredCount,
    required this.currentCount,
  });

  bool get isUnlocked => currentCount >= requiredCount;
  double get progress => (currentCount / requiredCount).clamp(0.0, 1.0);
}

// --- HEDEF MODELİ ---
class UserGoal {
  final String id;
  final CategoryType targetType;
  final int targetCount;
  final int currentCount;
  final String year;

  UserGoal({
    required this.id,
    required this.targetType,
    required this.targetCount,
    required this.currentCount,
    required this.year,
  });

  double get progress => (currentCount / targetCount).clamp(0.0, 1.0);
}

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

  List<UserBadge> _badges = [];
  List<UserGoal> _goals = [];

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final res = await _supabase.from('items').select().eq('user_id', userId);
      final items = (res as List).map((e) => ItemModel.fromMap(e, e['id'])).toList();
      
      int totalMin = 0;
      Map<String, int> typeCount = {};
      
      final currentYear = DateTime.now().year.toString();
      Map<String, int> thisYearCount = {};
      Map<String, int> genreCount = {};

      // Init type counters
      for (var type in CategoryType.values) {
        typeCount[type.name] = 0;
        thisYearCount[type.name] = 0;
      }

      for (var item in items) {
        if (item.runtime != null && item.watchStatus == 'watched') {
          totalMin += item.runtime!;
        } else if (item.runtime != null && item.watchStatus == 'watching' && item.seasonsData != null) {
          final selectedEps = item.selectedEpisodesCount;
          final totalEps = item.totalEpisodesCount;
          if (totalEps > 0 && selectedEps > 0) {
             double ratio = selectedEps / totalEps;
             totalMin += (item.runtime! * ratio).round();
          }
        }

        String typeName = item.mediaType ?? CategoryType.custom.name;
        // FIX: TMDB saves tv shows as 'tv', map it to 'tvShow' enum name
        if (typeName == 'tv') {
          typeName = CategoryType.tvShow.name;
        }

        typeCount[typeName] = (typeCount[typeName] ?? 0) + 1;
        
        if (item.createdAt.year.toString() == currentYear) {
           thisYearCount[typeName] = (thisYearCount[typeName] ?? 0) + 1;
        }

        for (var genre in item.genres) {
          if (genre.trim().isNotEmpty) {
            genreCount[genre] = (genreCount[genre] ?? 0) + 1;
          }
        }
      }

      var sortedGenres = genreCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      Map<String, int> topGenres = {};
      for (var i = 0; i < sortedGenres.length && i < 6; i++) {
        topGenres[sortedGenres[i].key] = sortedGenres[i].value;
      }

      _badges = [
        UserBadge(id: 'cinephile', title: AppStrings.isEn ? 'Cinephile' : 'Sinefil', description: AppStrings.isEn ? 'Watch 50 Movies' : '50 Film İzle', icon: Icons.movie_filter_rounded, requiredCount: 50, currentCount: typeCount[CategoryType.movie.name] ?? 0),
        UserBadge(id: 'binge', title: AppStrings.isEn ? 'Binge Watcher' : 'Dizi Kurdu', description: AppStrings.isEn ? 'Finish 30 Shows' : '30 Dizi Tamamla', icon: Icons.tv_rounded, requiredCount: 30, currentCount: typeCount[CategoryType.tvShow.name] ?? 0),
        UserBadge(id: 'bookworm', title: AppStrings.isEn ? 'Bookworm' : 'Kitapkurdu', description: AppStrings.isEn ? 'Read 20 Books' : '20 Kitap Oku', icon: Icons.menu_book_rounded, requiredCount: 20, currentCount: typeCount[CategoryType.book.name] ?? 0),
        UserBadge(id: 'gamer', title: AppStrings.isEn ? 'Gamer' : 'Oyuncu', description: AppStrings.isEn ? 'Play 20 Games' : '20 Oyun Oyna', icon: Icons.sports_esports_rounded, requiredCount: 20, currentCount: typeCount[CategoryType.game.name] ?? 0),
        UserBadge(id: 'music_lover', title: AppStrings.isEn ? 'Audiophile' : 'Müzikolog', description: AppStrings.isEn ? 'Log 50 Albums' : '50 Albüm/Şarkı', icon: Icons.headphones_rounded, requiredCount: 50, currentCount: typeCount[CategoryType.music.name] ?? 0),
        UserBadge(id: 'foodie', title: AppStrings.isEn ? 'Foodie' : 'Gurme', description: AppStrings.isEn ? 'Try 30 Foods' : '30 Yemek Dene', icon: Icons.restaurant_rounded, requiredCount: 30, currentCount: typeCount[CategoryType.food.name] ?? 0),
        UserBadge(id: 'traveler', title: AppStrings.isEn ? 'Explorer' : 'Gezgin', description: AppStrings.isEn ? 'Visit 20 Places' : '20 Mekan Gez', icon: Icons.flight_takeoff_rounded, requiredCount: 20, currentCount: typeCount[CategoryType.place.name] ?? 0),
        UserBadge(id: 'time_traveler', title: AppStrings.isEn ? 'Time Traveler' : 'Zaman Yolcusu', description: AppStrings.isEn ? '10k Mins Watched' : '10,000 Dk İzleme', icon: Icons.hourglass_top_rounded, requiredCount: 10000, currentCount: totalMin),
      ];

      await _loadGoals(thisYearCount, currentYear);

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

  Future<void> _loadGoals(Map<String, int> thisYearCount, String currentYear) async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList('user_custom_goals') ?? [];
    
    List<UserGoal> parsedGoals = [];
    for (var g in goalsJson) {
      try {
        final map = jsonDecode(g);
        if (map['year'] == currentYear) {
          final typeString = map['targetType'] as String;
          final catType = CategoryType.values.firstWhere((e) => e.name == typeString, orElse: () => CategoryType.movie);
          parsedGoals.add(UserGoal(
            id: map['id'],
            targetType: catType,
            targetCount: map['targetCount'],
            currentCount: thisYearCount[typeString] ?? 0,
            year: map['year'],
          ));
        }
      } catch (_) {}
    }
    _goals = parsedGoals;
  }

  Future<void> _addGoal(CategoryType type, int target) async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList('user_custom_goals') ?? [];
    
    final newGoal = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'targetType': type.name,
      'targetCount': target,
      'year': DateTime.now().year.toString(),
    };
    
    goalsJson.add(jsonEncode(newGoal));
    await prefs.setStringList('user_custom_goals', goalsJson);
    
    _fetchStatistics();
  }

  // YENİ: Hedef Silme Fonksiyonu
  Future<void> _deleteGoal(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList('user_custom_goals') ?? [];
    
    goalsJson.removeWhere((g) {
      try {
        final map = jsonDecode(g);
        return map['id'] == id;
      } catch (_) {
        return false;
      }
    });
    
    await prefs.setStringList('user_custom_goals', goalsJson);
    _fetchStatistics();
  }

  void _showAddGoalDialog() {
    CategoryType selectedType = CategoryType.movie;
    final targetCtrl = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(AppStrings.isEn ? 'Add New Goal' : 'Yeni Hedef Ekle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<CategoryType>(
                  value: selectedType,
                  items: CategoryType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Text(type.defaultEmoji),
                          const SizedBox(width: 8),
                          Text(type.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedType = val);
                    }
                  },
                  decoration: InputDecoration(labelText: AppStrings.isEn ? 'Content Type' : 'İçerik Türü'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: AppStrings.isEn ? 'Target Number (e.g. 50)' : 'Hedef Sayı (Örn: 50)'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.isEn ? 'Cancel' : 'İptal')),
              ElevatedButton(
                onPressed: () {
                  final target = int.tryParse(targetCtrl.text) ?? 10;
                  _addGoal(selectedType, target);
                  Navigator.pop(ctx);
                },
                child: Text(AppStrings.isEn ? 'Add' : 'Ekle'),
              ),
            ],
          );
        }
      ),
    );
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

  IconData _getIconForCategoryType(CategoryType type) {
    switch (type) {
      case CategoryType.movie: return Icons.movie_outlined;
      case CategoryType.tvShow: return Icons.tv_outlined;
      case CategoryType.book: return Icons.book_outlined;
      case CategoryType.game: return Icons.sports_esports_outlined;
      case CategoryType.music: return Icons.music_note_outlined;
      case CategoryType.food: return Icons.restaurant_outlined;
      case CategoryType.drink: return Icons.local_bar_outlined;
      case CategoryType.place: return Icons.place_outlined;
      case CategoryType.custom: return Icons.folder_special_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.isEn ? 'My Statistics & Badges' : 'İstatistik & Rozetler'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. SÜRE KARTI
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
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_totalMinutes),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppTheme.spaceXl),

                // 2. KİŞİSEL HEDEFLER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.isEn ? 'My Annual Goals' : 'Yıllık Hedeflerim', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppTheme.accent,
                      onPressed: _showAddGoalDialog,
                      tooltip: AppStrings.isEn ? 'Add Goal' : 'Yeni Hedef Ekle',
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSm),
                if (_goals.isEmpty)
                  Text(AppStrings.isEn ? 'No goals set yet. Click the + icon to add one!' : 'Henüz bir hedef belirlemedin. Artı butonuna basarak yeni bir hedef ekle!', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                ..._goals.map((goal) => _buildGoalCard(goal)),
                
                const SizedBox(height: AppTheme.spaceXl),

                // 3. ROZETLERİM
                Text(AppStrings.isEn ? 'Badges & Achievements' : 'Rozetlerim & Başarımlar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppTheme.spaceMd),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: _badges.map((b) => _buildBadgeCard(b)).toList(),
                ),

                const SizedBox(height: AppTheme.spaceXl),
                
                // 4. İÇERİK ÖZETİ
                Text(AppStrings.isEn ? 'Content Overview' : 'İçerik Özeti', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppTheme.spaceMd),
                Row(
                  children: [
                    _buildStatCard(AppStrings.isEn ? 'Total' : 'Toplam', _totalItems.toString(), Icons.storage_rounded),
                    const SizedBox(width: AppTheme.spaceMd),
                    _buildStatCard(CategoryType.movie.displayName, (_itemsByType[CategoryType.movie.name] ?? 0).toString(), _getIconForCategoryType(CategoryType.movie)),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMd),
                Row(
                  children: [
                    _buildStatCard(CategoryType.tvShow.displayName, (_itemsByType[CategoryType.tvShow.name] ?? 0).toString(), _getIconForCategoryType(CategoryType.tvShow)),
                    const SizedBox(width: AppTheme.spaceMd),
                    _buildStatCard(CategoryType.book.displayName, (_itemsByType[CategoryType.book.name] ?? 0).toString(), _getIconForCategoryType(CategoryType.book)),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMd),
                Row(
                  children: [
                    _buildStatCard(CategoryType.game.displayName, (_itemsByType[CategoryType.game.name] ?? 0).toString(), _getIconForCategoryType(CategoryType.game)),
                    const SizedBox(width: AppTheme.spaceMd),
                    _buildStatCard(CategoryType.music.displayName, (_itemsByType[CategoryType.music.name] ?? 0).toString(), _getIconForCategoryType(CategoryType.music)),
                  ],
                ),

                const SizedBox(height: AppTheme.spaceXl),

                // 5. TÜR DAĞILIMI
                if (_genresCount.isNotEmpty) ...[
                  Text(AppStrings.isEn ? 'Top Genres' : 'Favori Türler', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppTheme.spaceLg),
                  SizedBox(
                    height: 250,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 60, sections: _getPieSections())),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Top ${_genresCount.length}', style: Theme.of(context).textTheme.bodySmall),
                            Text(AppStrings.isEn ? 'Genres' : 'Tür', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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

  Widget _buildGoalCard(UserGoal goal) {
    String typeName = goal.targetType.displayName;
    IconData icon = _getIconForCategoryType(goal.targetType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${goal.year} ${AppStrings.isEn ? 'Goal:' : 'Yılında'} ${goal.targetCount} $typeName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Text('${goal.currentCount} / ${goal.targetCount}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              // YENİ: Silme Butonu
              GestureDetector(
                onTap: () => _deleteGoal(goal.id),
                child: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 10,
              backgroundColor: Colors.grey.withOpacity(0.2),
              color: goal.progress >= 1.0 ? AppTheme.success : AppTheme.accent,
            ),
          ),
          if (goal.progress >= 1.0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(AppStrings.isEn ? '🎉 Goal Completed! Awesome!' : '🎉 Hedef Tamamlandı! Harikasın!', style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold)),
            )
        ],
      ),
    );
  }

  Widget _buildBadgeCard(UserBadge badge) {
    final color = badge.isUnlocked ? AppTheme.warning : Colors.grey.withOpacity(0.3);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: badge.isUnlocked ? 2 : 1),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(badge.icon, size: 48, color: color),
          const SizedBox(height: 8),
          Text(badge.title, style: TextStyle(fontWeight: FontWeight.bold, color: badge.isUnlocked ? null : Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(badge.description, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
          const Spacer(),
          if (!badge.isUnlocked)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: badge.progress,
                minHeight: 6,
                backgroundColor: Colors.grey.withOpacity(0.2),
                color: AppTheme.warning.withOpacity(0.5),
              ),
            )
          else
            Text(AppStrings.isEn ? 'UNLOCKED' : 'KİLİDİ AÇIK', style: const TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.bold))
        ],
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
            Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  final List<Color> _chartColors = [AppTheme.accent, AppTheme.success, Colors.orange, Colors.purple, Colors.teal, Colors.redAccent];

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
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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