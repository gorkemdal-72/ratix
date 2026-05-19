import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/app_strings.dart';
import '../../services/database_service.dart';
import '../../models/category_model.dart';
import '../../models/category_type.dart';
import '../../models/rating_type.dart';
import '../../services/settings_service.dart';
import '../../providers/theme_provider.dart';
import '../settings/settings_screen.dart';
import '../details/category_detail_screen.dart';

enum CategorySort { defaultSort, nameAsc, nameDesc }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();

  String _searchQuery = "";
  CategorySort _currentSort = CategorySort.defaultSort;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
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
            icon: const Icon(Icons.sort_rounded),
            tooltip: AppStrings.sort,
            onSelected: (val) => setState(() => _currentSort = val),
            itemBuilder: (context) => [
              _buildSortMenuItem(CategorySort.defaultSort, AppStrings.sortDefault, Icons.access_time_rounded),
              _buildSortMenuItem(CategorySort.nameAsc, AppStrings.sortNameAsc, Icons.sort_by_alpha_rounded),
              _buildSortMenuItem(CategorySort.nameDesc, AppStrings.sortNameDesc, Icons.sort_by_alpha_rounded),
            ],
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

          // ─── KATEGORİ LİSTESİ ───
          Expanded(
            child: StreamBuilder<List<CategoryModel>>(
              stream: _dbService.getCategoriesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 3,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                List<CategoryModel> categories = snapshot.data!;

                if (_searchQuery.isNotEmpty) {
                  categories = categories.where((c) => c.name.toLowerCase().contains(_searchQuery)).toList();
                }

                if (_currentSort == CategorySort.nameAsc) {
                  categories.sort((a, b) => a.name.compareTo(b.name));
                } else if (_currentSort == CategorySort.nameDesc) {
                  categories.sort((a, b) => b.name.compareTo(a.name));
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
            Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: category)));
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                      Row(
                        children: [
                          _buildSmallBadge(
                            category.categoryType.displayName,
                            Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          _buildSmallBadge(
                            _getRatingTypeName(category.ratingType),
                            AppTheme.accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Üç Nokta Menüsü
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).textTheme.bodySmall?.color),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete(context, () => _dbService.deleteCategory(category.id));
                    } else if (value == 'edit') {
                      _showEditCategoryDialog(context, category);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                          const SizedBox(width: AppTheme.spaceSm),
                          const Text(AppStrings.edit),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                          SizedBox(width: AppTheme.spaceSm),
                          Text(AppStrings.delete, style: TextStyle(color: AppTheme.danger)),
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
        color: color.withOpacity(0.08),
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
        title: const Text(AppStrings.deleteConfirm),
        content: const Text(AppStrings.deleteCategoryMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
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
            child: const Text(AppStrings.delete, style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  // ─── KATEGORİ EKLEME DİYALOĞU ───
  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    CategoryType selectedType = CategoryType.movie;
    String selectedEmoji = CategoryType.movie.defaultEmoji;
    RatingType selectedRatingType = RatingType.stars5;

    // Kategori tipleri grid'i
    final types = CategoryType.values;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text(AppStrings.newCategory),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Seçili emoji büyük gösterim ──
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                              : Theme.of(context).colorScheme.primary.withOpacity(0.04),
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
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
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
                  decoration: const InputDecoration(
                    labelText: AppStrings.categoryName,
                    prefixIcon: Icon(Icons.label_outline),
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
                    items: const [
                      DropdownMenuItem(value: RatingType.stars5, child: Text("⭐ 5 Yıldız")),
                      DropdownMenuItem(value: RatingType.score10, child: Text("🎯 1-10 Puan")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedRatingType = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.isNotEmpty
                    ? nameController.text
                    : selectedType.displayName;
                final newCategory = CategoryModel(
                  id: '',
                  name: name,
                  ratingType: selectedRatingType,
                  icon: selectedEmoji,
                  categoryType: selectedType,
                );
                final error = await _dbService.addCategory(newCategory);
                if (!ctx.mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Hata: $error'), backgroundColor: AppTheme.danger),
                  );
                } else {
                  Navigator.pop(ctx);
                }
              },
              child: const Text(AppStrings.createCategory),
            ),
          ],
        ),
      ),
    );
  }

  // ─── KATEGORİ DÜZENLEME DİYALOĞU ───
  void _showEditCategoryDialog(BuildContext context, CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    String selectedEmoji = category.icon;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text(AppStrings.editCategory),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
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
                  decoration: const InputDecoration(
                    labelText: AppStrings.categoryName,
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final error = await _dbService.updateCategory(category.id, nameController.text, selectedEmoji);
                  if (!ctx.mounted) return;
                  if (error != null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Güncellenemedi: $error'), backgroundColor: AppTheme.danger),
                    );
                  } else {
                    Navigator.pop(ctx);
                  }
                }
              },
              child: const Text(AppStrings.updateCategory),
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