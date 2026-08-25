import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';
import '../../core/app_strings.dart';
import '../../models/category_model.dart';
import '../../models/category_type.dart';
import '../../models/item_model.dart';
import '../../models/rating_type.dart';
import '../../services/database_service.dart';
import '../../services/search_service.dart';
import '../../widgets/season_episode_selector_sheet.dart';
import '../social/create_post_screen.dart';

enum ItemSort { newest, oldest, ratingHigh, ratingLow, nameAsc, nameDesc, runtimeHigh, runtimeLow }

class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;
  const CategoryDetailScreen({super.key, required this.category});
  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  ItemSort _currentSort = ItemSort.newest;
  bool _showFavoritesOnly = false;
  String _searchQuery = '';
  String? _statusFilter; // null = all
  final TextEditingController _searchController = TextEditingController();

  CategoryModel? _selectedSubCategory;

  String get _activeCategoryId => _selectedSubCategory?.id ?? widget.category.id;

  List<String> _getRelevantIcons(CategoryType type) {
    switch (type) {
      case CategoryType.movie:
      case CategoryType.tvShow:
        return ['🎬', '🍿', '📺', '📼', '📽️', '🎭', '⭐', '🔥'];
      case CategoryType.book:
        return ['📚', '📖', '📝', '✍️', '📰', '📑', '🔖', '🎓'];
      case CategoryType.game:
        return ['🎮', '🕹️', '🎲', '🎯', '👾', '🏆', '⚔️', '🛡️'];
      case CategoryType.music:
        return ['🎵', '🎶', '🎧', '🎸', '🎹', '🎤', '🎷', '📻'];
      case CategoryType.custom:
      default:
        return ['📂', '🥤', '☕', '🍕', '🍰', '🍿', '⭐', '🏷️'];
    }
  }

  static const List<String> _allIcons = [
    '🥤', '☕', '🍵', '🧃', '🧋', '🍺', '🍷', '🍹', '🍕', '🍔', '🍟', '🌭', '🍿', '🍰', '🍩', '🍦',
    '🎬', '📺', '📽️', '📼', '🎭', '📷', '🎵', '🎶', '🎧', '🎸', '🎹', '🎤', '🎮', '🕹️', '🎲', '🎯',
    '📚', '📖', '📝', '✍️', '📰', '🎓', '🎨', '💼', '📂', '⭐', '🌟', '❤️', '🔥', '✨', '🏷️', '📌', '💡', '🏆', '💎', '🚀', '⚡'
  ];

  List<String> get _statusOptions {
    final cat = widget.category;
    final opts = [cat.status1Label, cat.status3Label];
    if (cat.status2Label != null) opts.insert(1, cat.status2Label!);
    return opts;
  }

  Widget _buildSubCategoryBar() {
    // Sadece üst seviye kategoriler alt kategoriye sahip olabilir
    if (widget.category.isSubCategory) return const SizedBox.shrink();

    return StreamBuilder<List<CategoryModel>>(
      stream: _dbService.getSubCategoriesStream(widget.category.id),
      builder: (context, snapshot) {
        final subCats = snapshot.data ?? [];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              FilterChip(
                selected: _selectedSubCategory == null,
                label: const Text('Tümü'),
                onSelected: (_) => setState(() => _selectedSubCategory = null),
                selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 8),
              ...subCats.map((subCat) {
                final isSelected = _selectedSubCategory?.id == subCat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onLongPress: () => _showEditSubCategoryDialog(subCat),
                    child: FilterChip(
                      selected: isSelected,
                      avatar: Text(subCat.icon, style: const TextStyle(fontSize: 14)),
                      label: Text(subCat.name),
                      onSelected: (_) => setState(() => _selectedSubCategory = isSelected ? null : subCat),
                      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                );
              }),
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Alt Kategori Ekle'),
                onPressed: _showAddSubCategoryDialog,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddSubCategoryDialog() {
    final nameCtrl = TextEditingController();
    final relevantIcons = _getRelevantIcons(widget.category.categoryType);
    String selectedIcon = relevantIcons.first;
    bool showMore = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final displayIcons = showMore ? _allIcons : relevantIcons;

          return AlertDialog(
            title: Text('${widget.category.name} Altına Alt Kategori Ekle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Alt Kategori Adı',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Simge Seç:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...displayIcons.map((icon) {
                        final isSelected = selectedIcon == icon;
                        return ChoiceChip(
                          label: Text(icon, style: const TextStyle(fontSize: 18)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => selectedIcon = icon),
                        );
                      }),
                      if (!showMore)
                        ActionChip(
                          avatar: const Icon(Icons.add_reaction_outlined, size: 16),
                          label: const Text('Daha Fazla İkon'),
                          onPressed: () => setState(() => showMore = true),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isNotEmpty) {
                    final subCat = CategoryModel(
                      id: '',
                      name: name,
                      icon: selectedIcon,
                      categoryType: widget.category.categoryType,
                      ratingType: widget.category.ratingType,
                      parentId: widget.category.id,
                      customStatus1: widget.category.customStatus1,
                      customStatus2: widget.category.customStatus2,
                      customStatus3: widget.category.customStatus3,
                    );
                    Navigator.pop(ctx);
                    await _dbService.addCategory(subCat);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$name alt kategorisi eklendi! ✦')),
                      );
                    }
                  }
                },
                child: const Text('Oluştur'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditSubCategoryDialog(CategoryModel subCat) {
    final nameCtrl = TextEditingController(text: subCat.name);
    final relevantIcons = _getRelevantIcons(widget.category.categoryType);
    String selectedIcon = subCat.icon;
    bool showMore = _allIcons.contains(subCat.icon) && !relevantIcons.contains(subCat.icon);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final displayIcons = showMore ? _allIcons : relevantIcons;

          return AlertDialog(
            title: const Text('Alt Kategoriyi Düzenle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Alt Kategori Adı'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Simge Seç:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...displayIcons.map((icon) {
                        final isSelected = selectedIcon == icon;
                        return ChoiceChip(
                          label: Text(icon, style: const TextStyle(fontSize: 18)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => selectedIcon = icon),
                        );
                      }),
                      if (!showMore)
                        ActionChip(
                          avatar: const Icon(Icons.add_reaction_outlined, size: 16),
                          label: const Text('Daha Fazla İkon'),
                          onPressed: () => setState(() => showMore = true),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _dbService.deleteCategory(subCat.id);
                  if (_selectedSubCategory?.id == subCat.id) {
                    this.setState(() => _selectedSubCategory = null);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Alt kategori silindi.')),
                    );
                  }
                },
                child: Text(AppStrings.delete, style: const TextStyle(color: AppTheme.danger)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.pop(ctx);
                    await _dbService.updateCategory(subCat.id, name, selectedIcon);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alt kategori güncellendi! ✦')),
                      );
                    }
                  }
                },
                child: Text(AppStrings.save),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.category.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(widget.category.name),
        ]),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                _showFavoritesOnly ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                key: ValueKey(_showFavoritesOnly),
                color: _showFavoritesOnly ? AppTheme.danger : null,
              ),
            ),
            onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Listeyi Kopyala (Çoğalt)',
            onPressed: () async {
              showDialog(
                context: context, 
                barrierDismissible: false, 
                builder: (_) => const Center(child: CircularProgressIndicator())
              );
              try {
                final err = await _dbService.duplicateCategory(widget.category.id);
                if (mounted) {
                  Navigator.pop(context);
                  if (err == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Liste başarıyla kopyalandı!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $err')));
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bir hata oluştu: $e')));
                }
              }
            },
          ),
          PopupMenuButton<ItemSort>(
            icon: const Icon(Icons.swap_vertical_circle_outlined),
            onSelected: (v) => setState(() => _currentSort = v),
            itemBuilder: (_) => [
              _sortItem(ItemSort.newest, 'En Yeni (Eklenme)', Icons.access_time_rounded),
              _sortItem(ItemSort.oldest, 'En Eski (Eklenme)', Icons.history_rounded),
              _sortItem(ItemSort.ratingHigh, 'Puan (En Yüksek)', Icons.arrow_upward_rounded),
              _sortItem(ItemSort.ratingLow, 'Puan (En Düşük)', Icons.arrow_downward_rounded),
              _sortItem(ItemSort.nameAsc, 'İsim (A - Z)', Icons.sort_by_alpha_rounded),
              _sortItem(ItemSort.nameDesc, 'İsim (Z - A)', Icons.sort_by_alpha_rounded),
              _sortItem(ItemSort.runtimeHigh, 'Süre (En Uzun)', Icons.timer_rounded),
              _sortItem(ItemSort.runtimeLow, 'Süre (En Kısa)', Icons.timer_outlined),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: '${widget.category.name} içinde ara...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                  : null,
            ),
          ),
        ),
        _buildStatusChips(),
        _buildSubCategoryBar(),
        Expanded(
          child: StreamBuilder<List<ItemModel>>(
            stream: _selectedSubCategory != null
                ? _dbService.getItemsStream(_selectedSubCategory!.id)
                : _dbService.getMainCategoryItemsStream(widget.category.id),
            builder: (ctx, snap) {
              if (!snap.hasData && snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 3));
              if (!snap.hasData) return _emptyState();
              var items = snap.data!;
              if (_searchQuery.isNotEmpty) items = items.where((i) => i.title.toLowerCase().contains(_searchQuery)).toList();
              if (_showFavoritesOnly) items = items.where((i) => i.isFavorite).toList();
              if (_statusFilter != null) items = items.where((i) => _statusLabelFor(i) == _statusFilter).toList();
              items.sort((a, b) {
                switch (_currentSort) {
                  case ItemSort.newest:      return b.createdAt.compareTo(a.createdAt);
                  case ItemSort.oldest:      return a.createdAt.compareTo(b.createdAt);
                  case ItemSort.ratingHigh:  return b.rating.compareTo(a.rating);
                  case ItemSort.ratingLow:   return a.rating.compareTo(b.rating);
                  case ItemSort.nameAsc:     return a.title.compareTo(b.title);
                  case ItemSort.nameDesc:    return b.title.compareTo(a.title);
                  case ItemSort.runtimeHigh: return (b.runtime ?? 0).compareTo(a.runtime ?? 0);
                  case ItemSort.runtimeLow:  return (a.runtime ?? 0).compareTo(b.runtime ?? 0);
                }
              });
              if (items.isEmpty) return _emptyState();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTotalTimeBanner(items),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _buildItemCard(items[i]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.category.categoryType.hasApiSearch
            ? _showSearchDialog(context)
            : _showManualAddDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(AppStrings.addItem),
      ),
    );
  }

  String _statusLabelFor(ItemModel item) {
    final cat = widget.category;
    if (item.watchStatus == 'watching') return cat.status2Label ?? cat.status1Label;
    if (item.watchStatus == 'watchlist') return cat.status3Label;
    return cat.status1Label;
  }

  Widget _buildStatusChips() {
    final statuses = _statusOptions;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        _chip(AppStrings.statusAll, _statusFilter == null, () => setState(() => _statusFilter = null)),
        ...statuses.map((s) => _chip(s, _statusFilter == s, () => setState(() => _statusFilter = _statusFilter == s ? null : s))),
      ]),
    );
  }

  Widget _buildTotalTimeBanner(List<ItemModel> items) {
    if (widget.category.categoryType != CategoryType.movie && widget.category.categoryType != CategoryType.tvShow) {
      return const SizedBox.shrink();
    }

    // Geçmişte eklenen ve süresi eksik olan içeriklerin sürelerini otomatik olarak TMDB'den çekip DB'ye doldur
    _dbService.checkAndBackfillRuntimes(items);

    // "izlendi" olanların ve dizi/anime olup "izleniyor" olanların izlenen kısımlarının süresini topla
    final validItems = items.where((i) => i.watchStatus == 'watched' || i.watchStatus == 'watching');
    int totalMinutes = 0;
    for (var i in validItems) {
      if (i.runtime != null) {
        totalMinutes += i.runtime!;
      }
    }

    if (totalMinutes == 0) return const SizedBox.shrink();

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final days = hours ~/ 24;
    final remainingHours = hours % 24;
    final months = days ~/ 30;
    final remainingDays = days % 30;

    String timeStr = '';
    if (months > 0) timeStr += '$months Ay ';
    if (remainingDays > 0) timeStr += '$remainingDays Gün ';
    if (remainingHours > 0) timeStr += '$remainingHours Saat ';
    if (minutes > 0 && months == 0 && remainingDays == 0) timeStr += '$minutes Dk';

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.timer_outlined, color: Theme.of(context).colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toplam İzleme Süresi (İzlenenler)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr.trim(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(
            color: selected ? Colors.white : color,
            fontSize: 13, fontWeight: FontWeight.w600,
          )),
        ),
      ),
    );
  }
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.playlist_add_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(AppStrings.emptyList, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
    );
  }

  PopupMenuItem<ItemSort> _sortItem(ItemSort value, String text, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 20, color: _currentSort == value ? Theme.of(context).colorScheme.primary : null),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: _currentSort == value ? Theme.of(context).colorScheme.primary : null)),
      ]),
    );
  }

  Widget _buildItemCard(ItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRatingDialog(context, item),
        onLongPress: () => _showStatusDialog(context, item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.posterUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.posterUrl!,
                    width: 50,
                    height: 75,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.withValues(alpha: 0.2), width: 50, height: 75),
                    errorWidget: (context, url, error) => Container(color: Colors.grey.withValues(alpha: 0.2), width: 50, height: 75, child: const Icon(Icons.error)),
                  ),
                )
              else
                Container(
                  width: 50, height: 75,
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(widget.category.icon, style: const TextStyle(fontSize: 24))),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (item.year != null || item.genres.isNotEmpty)
                      Text(
                        [if (item.year != null) item.year.toString(), if (item.genres.isNotEmpty) item.genres.first].join(' • '),
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _statusBadge(item),
                        if (item.seasonsSummary != null) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _editItemSeasons(context, item),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.tv_rounded, size: 12, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.seasonsSummary!,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _dbService.toggleFavorite(widget.category.id, item.id, item.isFavorite),
                          child: Icon(item.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: item.isFavorite ? AppTheme.danger : Colors.grey, size: 20),
                        ),
                      ],
                    ),
                    if (item.review != null && item.review!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                "' ${item.review!} '",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${AppStrings.isEn ? 'Added' : 'Eklendi'}: ${item.createdAt.day.toString().padLeft(2, '0')}.${item.createdAt.month.toString().padLeft(2, '0')}.${item.createdAt.year}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (item.watchStatus != 'watchlist')
                    _buildRatingBadge(item.rating)
                  else
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.bookmark_rounded, color: Colors.grey, size: 18),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                    onPressed: () => _confirmDelete(context, () => _dbService.deleteItem(widget.category.id, item.id)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(ItemModel item) {
    final cat = widget.category;
    String label = cat.status1Label;
    Color color = AppTheme.success;
    if (item.watchStatus == 'watching') {
      label = cat.status2Label ?? cat.status1Label;
      color = AppTheme.warning;
    } else if (item.watchStatus == 'watchlist') {
      label = cat.status3Label; 
      color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _showStatusDialog(BuildContext context, ItemModel item) {
    final cat = widget.category;
    final opts = [
      {'val': 'watched', 'label': cat.status1Label, 'icon': cat.categoryType.status1Emoji},
      if (cat.status2Label != null)
        {'val': 'watching', 'label': cat.status2Label!, 'icon': cat.categoryType.status2Emoji},
      {'val': 'watchlist', 'label': cat.status3Label, 'icon': cat.categoryType.status3Emoji},
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text(AppStrings.changeStatus, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            ...opts.map((o) => ListTile(
              leading: Text(o['icon'] as String, style: const TextStyle(fontSize: 24)),
              title: Text(o['label'] as String),
              trailing: item.watchStatus == o['val'] ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
              onTap: () {
                _dbService.updateItemStatus(widget.category.id, item.id, o['val'] as String);
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }
  Widget _buildRatingBadge(double rating) {
    final max = widget.category.ratingType == RatingType.stars5 ? 5.0 : 10.0;
    final color = AppTheme.ratingColor(rating, max);
    if (widget.category.ratingType == RatingType.score10) {
      return Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text(rating.toInt().toString(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      );
    }
    final d = rating == 0 ? "—" : rating % 1 == 0 ? rating.toInt().toString() : rating.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(d, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color, fontSize: 14)), const SizedBox(width: 2), Icon(Icons.star_rounded, color: color, size: 16)],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, ItemModel item) {
    double current = item.rating;
    final reviewCtrl = TextEditingController(text: item.review ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
        title: Text(item.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.watchStatus != 'watchlist') ...[
                _buildRatingInput(current, (v) => setState(() => current = v)),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_outline, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'Bu öğe henüz ${widget.category.categoryType.status3Label} durumunda. Puanlamak için önce durumunu değiştir.',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: reviewCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Yorum / Düşünceler',
                  hintText: 'Güncellemek için yaz...',
                  prefixIcon: Icon(Icons.rate_review_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () {
              final reviewText = reviewCtrl.text.trim().isEmpty ? null : reviewCtrl.text.trim();
              _dbService.updateItemRatingAndReview(widget.category.id, item.id, current, reviewText);
              Navigator.pop(ctx);
            },
            child: Text(AppStrings.updateItem),
          ),
        ],
      )),
    );
  }

  Widget _buildRatingInput(double current, Function(double) onChanged) {
    if (widget.category.ratingType == RatingType.score10) {
      final color = AppTheme.ratingColor(current, 10);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text(current.toInt().toString(), style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: color)), const SizedBox(width: 4), const Text("/10", style: TextStyle(fontSize: 20, color: Colors.grey))],
          ),
          SliderTheme(
            data: SliderThemeData(activeTrackColor: color, thumbColor: color, inactiveTrackColor: color.withValues(alpha: 0.2)),
            child: Slider(value: current, min: 1, max: 10, divisions: 9, label: current.toInt().toString(), onChanged: onChanged),
          ),
        ],
      );
    }
    final d = current == 0 ? "—" : current % 1 == 0 ? current.toInt().toString() : current.toStringAsFixed(1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(d, style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: current > 0 ? Colors.amber : Colors.grey)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final f = (i + 1).toDouble();
            final h = i + 0.5;
            final isF = current >= f;
            final isH = !isF && current >= h;
            return GestureDetector(
              onTap: () {
                if (current == f) {
                  onChanged(h);
                } else if (current == h) {
                  onChanged(i == 0 ? 0 : i.toDouble());
                } else {
                  onChanged(f);
                }
              },
              child: AnimatedScale(
                scale: current >= h ? 1.12 : 0.88,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: isF ? const Icon(Icons.star_rounded, color: Colors.amber, size: 46) : isH ? const Icon(Icons.star_half_rounded, color: Colors.amber, size: 46) : const Icon(Icons.star_outline_rounded, color: Colors.grey, size: 46),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Future<String?> Function() onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.deleteConfirm),
        content: Text(AppStrings.deleteItemMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () { onDelete(); Navigator.pop(ctx); },
            child: Text(AppStrings.delete, style: const TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  void _showManualAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final reviewCtrl = TextEditingController();
    double current = widget.category.ratingType == RatingType.stars5 ? 3.0 : 5.0;
    File? selectedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
        title: Text(AppStrings.addItem),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: InputDecoration(labelText: AppStrings.itemTitle, prefixIcon: const Icon(Icons.title_rounded))),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                  if (image != null) {
                    setState(() => selectedImage = File(image.path));
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: selectedImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(selectedImage!, fit: BoxFit.cover))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 40, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            const Text('Fotoğraf Ekle (Opsiyonel)', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              _buildRatingInput(current, (v) => setState(() => current = v)),
              const SizedBox(height: 16),
              TextField(
                controller: reviewCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Yorum / Düşünceler (opsiyonel)',
                  hintText: 'Bu hakkında ne düşünüyorsun?',
                  prefixIcon: Icon(Icons.rate_review_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: isUploading ? null : () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: isUploading ? null : () async {
              if (titleCtrl.text.isNotEmpty) {
                setState(() => isUploading = true);
                String? posterUrl;
                
                if (selectedImage != null) {
                  try {
                    final bytes = await selectedImage!.readAsBytes();
                    final fileExt = selectedImage!.path.split('.').last;
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
                    final filePath = '${Supabase.instance.client.auth.currentUser!.id}/$fileName';
                    
                    await Supabase.instance.client.storage
                        .from('avatars')
                        .uploadBinary(filePath, bytes);
                        
                    posterUrl = Supabase.instance.client.storage
                        .from('avatars')
                        .getPublicUrl(filePath);
                  } catch (e) {
                    debugPrint('Fotoğraf yükleme hatası: $e');
                  }
                }

                final reviewText = reviewCtrl.text.trim().isEmpty ? null : reviewCtrl.text.trim();
                final item = ItemModel(
                  id: '', 
                  title: titleCtrl.text, 
                  rating: current, 
                  createdAt: DateTime.now(),
                  review: reviewText,
                  posterUrl: posterUrl,
                  categoryId: _activeCategoryId,
                );
                
                final String newId = await _dbService.addItem(_activeCategoryId, item);
                
                if (mounted) {
                  Navigator.pop(ctx);
                  final savedItem = item.copyWith(id: newId);
                  _showQuickShareDialog(context, savedItem);
                }
              }
            },
            child: isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : Text(AppStrings.saveItem),
          ),
        ],
      )),
    );
  }

  void _editItemSeasons(BuildContext context, ItemModel item) async {
    if (item.externalId == null || item.externalId!.isEmpty) return;
    final searchRes = SearchResult(
      externalId: item.externalId!,
      title: item.title,
      posterUrl: item.posterUrl,
      year: item.year,
      mediaType: 'tv',
      genres: item.genres,
      overview: item.overview,
    );

    final seasonRes = await SeasonEpisodeSelectorSheet.show(
      context,
      tvResult: searchRes,
      initialSeasonsData: item.seasonsData,
    );

    if (seasonRes != null && mounted) {
      final int runtime = seasonRes['calculated_runtime'] as int? ?? 0;
      await _dbService.updateItemSeasons(item.id, seasonRes, runtime);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sezon ve Bölüm seçimleri güncellendi! ✦')),
        );
      }
    }
  }

  void _showSearchDialog(BuildContext context) async {
    final dynamic result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchBottomSheet(category: widget.category),
    );
    if (!mounted) return;
    if (result == 'MANUAL') {
      _showManualAddDialog(context);
    } else if (result is SearchResult) {
      if (result.mediaType == 'tv' || widget.category.categoryType == CategoryType.tvShow) {
        final seasonRes = await SeasonEpisodeSelectorSheet.show(context, tvResult: result);
        if (seasonRes != null && mounted) {
          _showApiAddDialog(context, result, seasonRes: seasonRes);
        }
      } else {
        _showApiAddDialog(context, result);
      }
    }
  }

  void _showApiAddDialog(BuildContext context, SearchResult r, {Map<String, dynamic>? seasonRes}) {
    double currentRating = widget.category.ratingType == RatingType.stars5 ? 3.0 : 5.0;
    final bool isTv = r.mediaType == 'tv' || widget.category.categoryType == CategoryType.tvShow;
    bool isAllSelected = true;
    int selectedEpCount = -1;
    if (isTv && seasonRes != null) {
      isAllSelected = seasonRes['all_selected'] == true;
      selectedEpCount = seasonRes['selected_episodes_count'] ?? 0;
    }
    String selectedStatus = (isTv && !isAllSelected) ? 'watching' : 'watched';
    if (isTv && selectedEpCount == 0) {
      selectedStatus = 'watchlist';
    }
    final reviewCtrl = TextEditingController();
    Map<String, dynamic>? currentSeasonRes = seasonRes;

    final cat = widget.category;
    final statusOpts = [
      {'val': 'watched', 'label': cat.status1Label},
      if (cat.status2Label != null) {'val': 'watching', 'label': cat.status2Label!},
      {'val': 'watchlist', 'label': cat.status3Label},
    ];

    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
        title: Text(r.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (r.posterUrl != null) 
                ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: r.posterUrl!, height: 120, fit: BoxFit.cover)),
              const SizedBox(height: 16),
              if (r.mediaType == 'tv' || widget.category.categoryType == CategoryType.tvShow) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tv_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSeasonRes != null
                                  ? (currentSeasonRes!['all_selected'] == true
                                      ? 'Tüm Dizi (${currentSeasonRes!['selected_episodes_count']} Bölüm)'
                                      : '${currentSeasonRes!['selected_episodes_count']} Bölüm Seçildi')
                                  : 'Sezon & Bölüm Seçimi',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            if (currentSeasonRes != null && currentSeasonRes!['calculated_runtime'] != null)
                              Text(
                                '~${currentSeasonRes!['calculated_runtime']} dk izleme süresi',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                        onPressed: () async {
                          final updatedRes = await SeasonEpisodeSelectorSheet.show(
                            context,
                            tvResult: r,
                            initialSeasonsData: currentSeasonRes,
                          );
                          if (updatedRes != null) {
                            setState(() {
                              currentSeasonRes = updatedRes;
                              final bool allSel = updatedRes['all_selected'] == true;
                              final int count = updatedRes['selected_episodes_count'] ?? 0;
                              selectedStatus = allSel ? 'watched' : (count == 0 ? 'watchlist' : 'watching');
                            });
                          }
                        },
                        child: const Text('Düzenle', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: InputDecoration(labelText: AppStrings.changeStatus),
                items: statusOpts.map((o) => DropdownMenuItem(value: o['val'], child: Text(o['label']!))).toList(),
                onChanged: (v) => setState(() => selectedStatus = v!),
              ),
              const SizedBox(height: 16),
              _buildRatingInput(currentRating, (v) => setState(() => currentRating = v)),
              const SizedBox(height: 16),
              TextField(
                controller: reviewCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Yorum / Düşünceler (opsiyonel)',
                  hintText: 'Bu hakkında ne düşünüyorsun?',
                  prefixIcon: Icon(Icons.rate_review_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: isSaving ? null : () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: isSaving ? null : () async {
              setState(() => isSaving = true);
              final reviewText = reviewCtrl.text.trim().isEmpty ? null : reviewCtrl.text.trim();
              
              int? fetchedRuntime;
              if (currentSeasonRes != null && currentSeasonRes!['calculated_runtime'] != null) {
                fetchedRuntime = currentSeasonRes!['calculated_runtime'] as int?;
              } else if (r.externalId.isNotEmpty && r.mediaType.isNotEmpty) {
                 fetchedRuntime = await SearchService.instance.getTmdbRuntime(r.mediaType, r.externalId);
              }

              final item = ItemModel(
                id: '', title: r.title, rating: currentRating, createdAt: DateTime.now(),
                watchStatus: selectedStatus, posterUrl: r.posterUrl, year: r.year, 
                externalId: r.externalId, mediaType: r.mediaType, genres: r.genres, 
                author: r.author, overview: r.overview, review: reviewText,
                runtime: fetchedRuntime, categoryId: _activeCategoryId,
                seasonsData: currentSeasonRes,
              );
              Navigator.pop(ctx);
              final String newId = await _dbService.addItem(_activeCategoryId, item);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eklendi! ✦')));
                final savedItem = item.copyWith(id: newId);
                _showQuickShareDialog(context, savedItem);
              }
            },
            child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(AppStrings.saveItem),
          ),
        ],
      )),
    );
  }

  void _showQuickShareDialog(BuildContext context, ItemModel item) async {
    final prefs = await SharedPreferences.getInstance();
    final showSharePrompt = prefs.getBool('show_quick_share_prompt') ?? true;
    if (!showSharePrompt) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.share_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Paylaşmak ister misin?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (item.posterUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(imageUrl: item.posterUrl!, width: 40, height: 60, fit: BoxFit.cover),
                    )
                  else
                    Container(
                      width: 40, height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text(widget.category.icon, style: const TextStyle(fontSize: 20))),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (item.rating > 0)
                          Text('Puan: ${item.rating}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu öneriyi Ayarlar menüsünden kapatabilirsiniz.',
              style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hayır'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CreatePostScreen(preSelectedItem: item),
              ));
            },
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Paylaş'),
          ),
        ],
      ),
    );
  }
}

class _SearchBottomSheet extends StatefulWidget {
  final CategoryModel category;
  const _SearchBottomSheet({required this.category});
  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  final TextEditingController _ctrl = TextEditingController();
  List<SearchResult> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _search(q);
    });
  }
  
  String _currentQuery = '';

  void _search(String q) async {
    if (q.isEmpty) { 
      _currentQuery = '';
      if (mounted) setState(() { _results = []; _loading = false; }); 
      return; 
    }
    
    _currentQuery = q;
    if (mounted) setState(() { _loading = true; });
    
    final res = await SearchService.instance.search(widget.category.categoryType, q);
    
    // Eğer yanıt geldiğinde kullanıcı başka bir şey aramışsa, bu yanıtı (stale) çöpe at
    if (_currentQuery != q) return;
    
    if (mounted) setState(() { _results = res; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: AppStrings.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () { _ctrl.clear(); _search(''); }),
                    ),
                  ),
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.category.name} Ara',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, 'MANUAL'),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Manuel Ekle', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_results.isEmpty && _ctrl.text.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppStrings.noApiResult),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, 'MANUAL');
                      },
                      icon: const Icon(Icons.edit_note_rounded),
                      label: Text(AppStrings.addManually),
                    ),
                  ],
                ),
              ),
            )
          else Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (ctx, i) {
                final r = _results[i];
                return ListTile(
                  leading: r.posterUrl != null ? CachedNetworkImage(imageUrl: r.posterUrl!, width: 40, fit: BoxFit.cover) : const Icon(Icons.image),
                  title: Text(r.title),
                  subtitle: Text(
                    r.year != null ? 'Yıl: ${r.year}' : (r.subtitle ?? ''),
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  onTap: () {
                    Navigator.pop(context, r);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

