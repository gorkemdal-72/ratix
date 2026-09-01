import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/app_strings.dart';
import '../../services/database_service.dart';
import '../../models/category_model.dart';
import '../../models/category_type.dart';
import '../../models/item_model.dart';
import '../../models/rating_type.dart';
import '../../services/settings_service.dart';
import '../../providers/theme_provider.dart';
import '../settings/settings_screen.dart';
import '../discover/discover_screen.dart';
import '../calendar/calendar_screen.dart';
import '../details/category_detail_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

enum CategorySort { newest, oldest, nameAsc, nameDesc, type }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();

  String _searchQuery = "";
  CategorySort _currentSort = CategorySort.newest;
  final TextEditingController _searchController = TextEditingController();
  
  ItemModel? _closestUpcomingItem;
  bool _isLoadingUpcoming = true;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _fetchUpcoming();
  }

  Future<void> _fetchUpcoming() async {
    try {
      // Önce senkronize et (eski eklenmiş dizilerin tarihleri güncellensin)
      // UI'ı bloklamamak için await yapmıyor, arkada çalışmasını sağlıyoruz.
      _dbService.syncUpcomingTvShows().then((_) async {
        if (mounted) {
           final items = await _dbService.getUpcomingItems();
           if (mounted) {
             setState(() {
               _closestUpcomingItem = items.isNotEmpty ? items.first : null;
               _isLoadingUpcoming = false;
             });
           }
        }
      });
      
      final items = await _dbService.getUpcomingItems();
      if (mounted) {
        setState(() {
          _closestUpcomingItem = items.isNotEmpty ? items.first : null;
          _isLoadingUpcoming = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUpcoming = false);
    }
  }
  void _loadUserPreferences() async {
    final settingsData = await SettingsService().getUserData();
    if (settingsData != null && settingsData['preferences'] != null && mounted) {
      bool isDark = settingsData['preferences']['defaultTheme'] ?? false;
      Provider.of<ThemeProvider>(context, listen: false).toggleTheme(isDark);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.myCategories),
        actions: [
          PopupMenuButton<CategorySort>(
            icon: const Icon(Icons.swap_vertical_circle_outlined),
            tooltip: AppStrings.sort,
            onSelected: (val) => setState(() => _currentSort = val),
            itemBuilder: (context) => [
              _buildSortMenuItem(CategorySort.newest, 'En Yeni (Oluşturma)', Icons.access_time_rounded),
              _buildSortMenuItem(CategorySort.oldest, 'En Eski (Oluşturma)', Icons.history_rounded),
              _buildSortMenuItem(CategorySort.nameAsc, 'İsim (A - Z)', Icons.sort_by_alpha_rounded),
              _buildSortMenuItem(CategorySort.nameDesc, 'İsim (Z - A)', Icons.sort_by_alpha_rounded),
              _buildSortMenuItem(CategorySort.type, 'Kategori Türü', Icons.category_rounded),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscoverScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ─── ARAMA ÇUBUĞU ───
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd, 4, AppTheme.spaceMd, AppTheme.spaceSm),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: AppStrings.searchCategory,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        })
                    : null,
              ),
            ),
          ),
          
          // ─── YAKLAŞANLAR WIDGET'I (DASHBOARD) ───
          if (!_isLoadingUpcoming && _closestUpcomingItem != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                        Theme.of(context).colorScheme.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.isEn ? 'Next Up:' : 'Yaklaşan:',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              _closestUpcomingItem!.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_closestUpcomingItem!.nextAirDate!.difference(DateTime.now()).inDays} gün',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ─── KATEGORİ LİSTESİ ───
          Expanded(
            child: StreamBuilder<List<CategoryModel>>(
              stream: _dbService.getCategoriesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 3,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                var categories = (snapshot.data ?? []).where((c) => !c.isSubCategory).toList();

                if (_searchQuery.isNotEmpty) {
                  categories = categories.where((c) => c.name.toLowerCase().contains(_searchQuery)).toList();
                }

                switch (_currentSort) {
                  case CategorySort.newest:
                    break;
                  case CategorySort.oldest:
                    categories = categories.reversed.toList();
                    break;
                  case CategorySort.nameAsc:
                    categories.sort((a, b) => a.name.compareTo(b.name));
                    break;
                  case CategorySort.nameDesc:
                    categories.sort((a, b) => b.name.compareTo(a.name));
                    break;
                  case CategorySort.type:
                    categories.sort((a, b) => a.categoryType.displayName.compareTo(b.categoryType.displayName));
                    break;
                }

                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 56, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(height: AppTheme.spaceMd),
                        Text(
                          AppStrings.noSearchResult,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryCard(category);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Ekle"),
      ),
    );
  }

  // ─── KATEGORİ KARTI ───
  Widget _buildCategoryCard(CategoryModel category) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () {
            if (category.isPrivate) {
              _showPasswordDialog(context, category);
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: category)));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: Row(
              children: [
                // Emoji Avatarı
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  alignment: Alignment.center,
                  child: Text(category.icon, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: AppTheme.spaceMd),
                // İsim + Tip badge'leri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildSmallBadge(
                            category.categoryType.displayName,
                            Theme.of(context).colorScheme.primary,
                          ),
                          _buildSmallBadge(
                            _getRatingTypeName(category.ratingType),
                            AppTheme.accent,
                          ),
                          _buildSmallBadge(
                            '${category.itemCount} Öğe',
                            Colors.blueGrey,
                          ),
                          if (category.isPrivate)
                            const Icon(Icons.lock_rounded, size: 16, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
                // Üç Nokta Menüsü
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).textTheme.bodySmall?.color),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      _confirmDelete(context, () => _dbService.deleteCategory(category.id));
                    } else if (value == 'edit') {
                      _showEditCategoryDialog(context, category);
                    } else if (value == 'copy') {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('copied_category_id', category.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Liste kopyalandı! (Başka bir listeye yapıştırabilirsiniz)')));
                      }
                    } else if (value == 'paste') {
                      final prefs = await SharedPreferences.getInstance();
                      final copiedId = prefs.getString('copied_category_id');
                      if (copiedId == null) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Önce kopyala yapmalısınız!')));
                        return;
                      }
                      if (copiedId == category.id) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aynı listeye yapıştıramazsınız!')));
                        return;
                      }
                      if (!mounted) return;
                      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                      final err = await _dbService.pasteCategoryItems(copiedId, category.id);
                      if (mounted) {
                        Navigator.pop(context);
                        if (err == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Öğeler başarıyla yapıştırıldı!')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $err')));
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                          const SizedBox(width: AppTheme.spaceSm),
                          Text(AppStrings.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                          const SizedBox(width: AppTheme.spaceSm),
                          const Text('Kopyala'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'paste',
                      child: Row(
                        children: [
                          Icon(Icons.paste_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                          const SizedBox(width: AppTheme.spaceSm),
                          const Text('Yapıştır'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                          const SizedBox(width: AppTheme.spaceSm),
                          Text(AppStrings.delete, style: const TextStyle(color: AppTheme.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  // ─── BOŞ DURUM ───
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: Icon(
                Icons.category_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Text(
              AppStrings.emptyCategories,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<CategorySort> _buildSortMenuItem(CategorySort value, String text, IconData icon) {
    final isSelected = _currentSort == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isSelected ? Theme.of(context).colorScheme.primary : null),
          const SizedBox(width: AppTheme.spaceSm),
          Text(text,
              style: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              )),
        ],
      ),
    );
  }

  String _getRatingTypeName(RatingType type) {
    switch (type) {
      case RatingType.stars5:
        return AppStrings.stars5;
      case RatingType.score10:
        return AppStrings.score10;
    }
  }

  void _confirmDelete(BuildContext context, Future<String?> Function() onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.deleteConfirm),
        content: Text(AppStrings.deleteCategoryMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await onDelete();
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Silinemedi: $error'), backgroundColor: AppTheme.danger),
                );
              }
            },
            child: Text(AppStrings.delete, style: const TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  // ─── KATEGORİ EKLEME DİYALOĞU ───
  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final status1Controller = TextEditingController();
    final status2Controller = TextEditingController();
    final status3Controller = TextEditingController();
    CategoryType selectedType = CategoryType.movie;
    String selectedEmoji = CategoryType.movie.defaultEmoji;
    RatingType selectedRatingType = RatingType.stars5;
    bool isPrivate = false;

    // Kategori tipleri grid'i
    final types = CategoryType.values;

    final scrollCtrl = ScrollController();
    final statusKey = GlobalKey();
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(AppStrings.newCategory),
          content: SingleChildScrollView(
            controller: scrollCtrl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dialogError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dialogError!,
                            style: const TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Seçili emoji büyük gösterim ──
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    alignment: Alignment.center,
                    child: Text(selectedEmoji, style: const TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),

                // ── Kategori Türü Seçici ──
                Text(
                  AppStrings.categoryTypeHint,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: types.map((type) {
                    final isSelected = selectedType == type;
                    return GestureDetector(
                      onTap: () => setState(() {
                        selectedType = type;
                        selectedEmoji = type.defaultEmoji;
                        dialogError = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(type.defaultEmoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              type.displayName,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.spaceLg),

                // ── Özel emoji seçimi (opsiyonel) ──
                Text(
                  "Özel emoji (opsiyonel)",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _extraEmojis.map((e) => GestureDetector(
                    onTap: () => setState(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selectedEmoji == e
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: selectedEmoji == e
                            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: AppTheme.spaceLg),

                // ── Liste adı ──
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.categoryName,
                    prefixIcon: const Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),

                // ── Durum Etiketlerini Özelleştirme ──
                KeyedSubtree(
                  key: statusKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedType == CategoryType.custom
                            ? AppStrings.statusOptionsCustomRequired
                            : AppStrings.statusOptionsOptional,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: selectedType == CategoryType.custom
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: status1Controller,
                              decoration: InputDecoration(
                                labelText: AppStrings.status1,
                                hintText: selectedType.status1Label,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: status2Controller,
                              decoration: InputDecoration(
                                labelText: AppStrings.status2,
                                hintText: selectedType.status2Label ?? (AppStrings.isEn ? 'In Progress' : 'Devam Ediyor'),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: status3Controller,
                        decoration: InputDecoration(
                          labelText: AppStrings.status3,
                          hintText: selectedType.status3Label,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),

                // ── Puanlama tipi ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: DropdownButton<RatingType>(
                    value: selectedRatingType,
                    isExpanded: true,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    items: [
                      DropdownMenuItem(value: RatingType.stars5, child: Text("⭐ ${AppStrings.stars5}")),
                      DropdownMenuItem(value: RatingType.score10, child: Text("🎯 ${AppStrings.score10}")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedRatingType = val);
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),

                // ── Gizlilik ──
                SwitchListTile(
                  title: Text(AppStrings.privateCategory),
                  subtitle: Text(AppStrings.privateCategorySub),
                  value: isPrivate,
                  onChanged: (val) => setState(() => isPrivate = val),
                  contentPadding: EdgeInsets.zero,
                ),
                if (isPrivate) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.categoryPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (isPrivate && passwordController.text.trim().isEmpty) {
                  setState(() {
                    dialogError = 'Lütfen kategori için bir şifre belirleyin.';
                  });
                  return;
                }

                final name = nameController.text.isNotEmpty
                    ? nameController.text
                    : selectedType.displayName;
                
                String? passwordHash;
                if (isPrivate) {
                  passwordHash = sha256.convert(utf8.encode(passwordController.text.trim())).toString();
                }

                final cStatus1 = status1Controller.text.trim().isNotEmpty ? status1Controller.text.trim() : null;
                final cStatus2 = status2Controller.text.trim().isNotEmpty ? status2Controller.text.trim() : null;
                final cStatus3 = status3Controller.text.trim().isNotEmpty ? status3Controller.text.trim() : null;

                if (selectedType == CategoryType.custom && (cStatus1 == null || cStatus3 == null)) {
                  setState(() {
                    dialogError = 'Lütfen Özel kategori için en az 1. ve 3. Durum adlarını giriniz! (Örn: Tamamlandı, Yapılacak)';
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (statusKey.currentContext != null) {
                      Scrollable.ensureVisible(
                        statusKey.currentContext!,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    }
                  });
                  return;
                }

                final newCategory = CategoryModel(
                  id: '',
                  name: name,
                  ratingType: selectedRatingType,
                  icon: selectedEmoji,
                  categoryType: selectedType,
                  isPrivate: isPrivate,
                  passwordHash: passwordHash,
                  customStatus1: cStatus1,
                  customStatus2: cStatus2,
                  customStatus3: cStatus3,
                );
                final error = await _dbService.addCategory(newCategory);
                if (!ctx.mounted) return;
                if (error != null) {
                  setState(() {
                    dialogError = 'Hata: $error';
                  });
                } else {
                  Navigator.pop(ctx);
                }
              },
              child: Text(AppStrings.createCategory),
            ),
          ],
        ),
      ),
    );
  }

  // ─── KATEGORİ DÜZENLEME DİYALOĞU ───
  void _showEditCategoryDialog(BuildContext context, CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    final status1Controller = TextEditingController(text: category.customStatus1 ?? '');
    final status2Controller = TextEditingController(text: category.customStatus2 ?? '');
    final status3Controller = TextEditingController(text: category.customStatus3 ?? '');
    String selectedEmoji = category.icon;
    final isCustom = category.categoryType == CategoryType.custom;
    final scrollCtrl = ScrollController();
    final statusKey = GlobalKey();
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(AppStrings.editCategory),
          content: SingleChildScrollView(
            controller: scrollCtrl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dialogError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dialogError!,
                            style: const TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    alignment: Alignment.center,
                    child: Text(selectedEmoji, style: const TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _extraEmojis.map((e) => GestureDetector(
                    onTap: () => setState(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selectedEmoji == e
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: selectedEmoji == e
                            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: AppTheme.spaceLg),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.categoryName,
                    prefixIcon: const Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),

                // ── Durum Etiketlerini Düzenleme ──
                KeyedSubtree(
                  key: statusKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCustom ? AppStrings.statusOptionsRequired : AppStrings.statusOptionsEdit,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCustom ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: status1Controller,
                              decoration: InputDecoration(
                                labelText: AppStrings.status1,
                                hintText: category.categoryType.status1Label,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: status2Controller,
                              decoration: InputDecoration(
                                labelText: AppStrings.status2,
                                hintText: category.categoryType.status2Label ?? (AppStrings.isEn ? 'In Progress' : 'Devam Ediyor'),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: status3Controller,
                        decoration: InputDecoration(
                          labelText: AppStrings.status3,
                          hintText: category.categoryType.status3Label,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                final c1 = status1Controller.text.trim();
                final c2 = status2Controller.text.trim();
                final c3 = status3Controller.text.trim();

                if (isCustom && (c1.isEmpty || c3.isEmpty)) {
                  setState(() {
                    dialogError = 'Lütfen Özel kategori için en az 1. ve 3. Durum seçeneklerini belirleyin!';
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (statusKey.currentContext != null) {
                      Scrollable.ensureVisible(
                        statusKey.currentContext!,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    }
                  });
                  return;
                }

                final error = await _dbService.updateCategory(
                  category.id,
                  nameController.text.trim(),
                  selectedEmoji,
                  customStatus1: c1.isNotEmpty ? c1 : null,
                  customStatus2: c2.isNotEmpty ? c2 : null,
                  customStatus3: c3.isNotEmpty ? c3 : null,
                );

                if (!ctx.mounted) return;
                if (error != null) {
                  setState(() {
                    dialogError = 'Güncellenemedi: $error';
                  });
                } else {
                  Navigator.pop(ctx);
                }
              },
              child: Text(AppStrings.updateCategory),
            ),
          ],
        ),
      ),
    );
  }
  // ─── KATEGORİ ŞİFRESİ GİRİŞ DİYALOĞU ───
  void _showPasswordDialog(BuildContext context, CategoryModel category) {
    final passwordController = TextEditingController();
    bool error = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_rounded, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(child: Text('${category.name} (Özel)', overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bu kategoriye erişmek için şifre giriniz.'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: const Icon(Icons.password_rounded),
                  errorText: error ? 'Hatalı şifre' : null,
                ),
                onSubmitted: (_) {
                  final inputHash = sha256.convert(utf8.encode(passwordController.text.trim())).toString();
                  if (inputHash == category.passwordHash) {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: category)));
                  } else {
                    setState(() => error = true);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
            ElevatedButton(
              onPressed: () {
                final inputHash = sha256.convert(utf8.encode(passwordController.text.trim())).toString();
                if (inputHash == category.passwordHash) {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: category)));
                } else {
                  setState(() => error = true);
                }
              },
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _extraEmojis = [
    '🎬', '📺', '📚', '🎮', '🎵', '🍽️', '🍺', '✈️', '📁',
    '🎭', '🎸', '🏋️', '🎨', '🐕', '🍕', '☕', '🍜', '🏖️',
    '🧠', '💻', '⚽', '🏀', '🎤', '🎧', '🍷', '🥂', '🌍',
  ];
}