import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/app_strings.dart';
import '../../models/category_model.dart';
import '../../models/category_type.dart';
import '../../models/item_model.dart';
import '../../models/rating_type.dart';
import '../../services/database_service.dart';
import '../../services/search_service.dart';

enum ItemSort { newest, ratingHigh, ratingLow, nameAsc }

class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;
  const CategoryDetailScreen({super.key, required this.category});
  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  final SearchService _searchSvc = SearchService.instance;
  ItemSort _currentSort = ItemSort.newest;
  bool _showFavoritesOnly = false;
  String _searchQuery = '';
  String? _statusFilter; // null = all
  final TextEditingController _searchController = TextEditingController();

  List<String> get _statusOptions {
    final t = widget.category.categoryType;
    final opts = [t.status1Label, t.status3Label];
    if (t.status2Label != null) opts.insert(1, t.status2Label!);
    return opts;
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
          PopupMenuButton<ItemSort>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (v) => setState(() => _currentSort = v),
            itemBuilder: (_) => [
              _sortItem(ItemSort.newest, AppStrings.sortNewest, Icons.access_time_rounded),
              _sortItem(ItemSort.ratingHigh, AppStrings.sortRatingHigh, Icons.arrow_upward_rounded),
              _sortItem(ItemSort.ratingLow, AppStrings.sortRatingLow, Icons.arrow_downward_rounded),
              _sortItem(ItemSort.nameAsc, AppStrings.sortNameAsc, Icons.sort_by_alpha_rounded),
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
              hintText: ' içinde ara...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                  : null,
            ),
          ),
        ),
        _buildStatusChips(),
        Expanded(
          child: StreamBuilder<List<ItemModel>>(
            stream: _dbService.getItemsStream(widget.category.id),
            builder: (ctx, snap) {
              if (!snap.hasData) return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 3));
              var items = snap.data!;
              if (_searchQuery.isNotEmpty) items = items.where((i) => i.title.toLowerCase().contains(_searchQuery)).toList();
              if (_showFavoritesOnly) items = items.where((i) => i.isFavorite).toList();
              if (_statusFilter != null) items = items.where((i) => _statusLabelFor(i) == _statusFilter).toList();
              items.sort((a, b) {
                switch (_currentSort) {
                  case ItemSort.ratingHigh: return b.rating.compareTo(a.rating);
                  case ItemSort.ratingLow:  return a.rating.compareTo(b.rating);
                  case ItemSort.nameAsc:    return a.title.compareTo(b.title);
                  case ItemSort.newest:     return b.createdAt.compareTo(a.createdAt);
                }
              });
              if (items.isEmpty) return _emptyState();
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (_, i) => _buildItemCard(items[i]),
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
        label: const Text(AppStrings.addItem),
      ),
    );
  }

  String _statusLabelFor(ItemModel item) {
    final t = widget.category.categoryType;
    if (item.watchStatus == 'watching') return t.status2Label ?? t.status1Label;
    if (item.watchStatus == 'watchlist') return t.status3Label;
    return t.status1Label;
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
            color: selected ? color : color.withOpacity(0.07),
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
          Icon(Icons.playlist_add_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
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
    final t = widget.category.categoryType;
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
                    placeholder: (context, url) => Container(color: Colors.grey.withOpacity(0.2), width: 50, height: 75),
                    errorWidget: (context, url, error) => Container(color: Colors.grey.withOpacity(0.2), width: 50, height: 75, child: const Icon(Icons.error)),
                  ),
                )
              else
                Container(
                  width: 50, height: 75,
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
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
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _dbService.toggleFavorite(widget.category.id, item.id, item.isFavorite),
                          child: Icon(item.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: item.isFavorite ? AppTheme.danger : Colors.grey, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _buildRatingBadge(item.rating),
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
    final t = widget.category.categoryType;
    String label = t.status1Label;
    Color color = AppTheme.success;
    if (item.watchStatus == 'watching') {
      label = t.status2Label ?? t.status1Label;
      color = AppTheme.warning;
    } else if (item.watchStatus == 'watchlist') {
      label = t.status3Label;
      color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _showStatusDialog(BuildContext context, ItemModel item) {
    final opts = [
      {'val': 'watched', 'label': widget.category.categoryType.status1Label, 'icon': widget.category.categoryType.status1Emoji},
      if (widget.category.categoryType.status2Label != null)
        {'val': 'watching', 'label': widget.category.categoryType.status2Label!, 'icon': widget.category.categoryType.status2Emoji},
      {'val': 'watchlist', 'label': widget.category.categoryType.status3Label, 'icon': widget.category.categoryType.status3Emoji},
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text(AppStrings.changeStatus, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
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
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text(rating.toInt().toString(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      );
    }
    final d = rating == 0 ? "—" : rating % 1 == 0 ? rating.toInt().toString() : rating.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(d, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color, fontSize: 14)), const SizedBox(width: 2), Icon(Icons.star_rounded, color: color, size: 16)],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, ItemModel item) {
    double current = item.rating;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
        title: Text(item.title),
        content: _buildRatingInput(current, (v) => setState(() => current = v)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () {
              _dbService.updateItemRating(widget.category.id, item.id, current);
              Navigator.pop(ctx);
            },
            child: const Text(AppStrings.updateItem),
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
            children: [const Text("??", style: TextStyle(fontSize: 32)), const SizedBox(width: 8), Text(current.toInt().toString(), style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: color))],
          ),
          SliderTheme(
            data: SliderThemeData(activeTrackColor: color, thumbColor: color, inactiveTrackColor: color.withOpacity(0.2)),
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
                if (isF) onChanged(h); else if (isH) onChanged(i == 0 ? 0 : i.toDouble()); else onChanged(f);
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
        title: const Text(AppStrings.deleteConfirm),
        content: const Text(AppStrings.deleteItemMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () { onDelete(); Navigator.pop(ctx); },
            child: const Text(AppStrings.delete, style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  void _showManualAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    double current = widget.category.ratingType == RatingType.stars5 ? 3.0 : 5.0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
        title: const Text(AppStrings.addItem),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: AppStrings.itemTitle, prefixIcon: Icon(Icons.title_rounded))),
              const SizedBox(height: 24),
              _buildRatingInput(current, (v) => setState(() => current = v)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                _dbService.addItem(widget.category.id, ItemModel(id: '', title: titleCtrl.text, rating: current, createdAt: DateTime.now()));
                Navigator.pop(ctx);
              }
            },
            child: const Text(AppStrings.saveItem),
          ),
        ],
      )),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchBottomSheet(category: widget.category),
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
  
  void _search(String q) async {
    if (q.isEmpty) { setState(() => _results = []); return; }
    setState(() { _loading = true; _results = []; });
    final res = await SearchService.instance.search(widget.category.categoryType, q);
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _search,
                    decoration: InputDecoration(
                      hintText: AppStrings.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () { _ctrl.clear(); _search(''); }),
                    ),
                  ),
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
              ],
            ),
          ),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_results.isEmpty && _ctrl.text.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(AppStrings.noApiResult),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Manual add call would ideally be routed here, handled by parent
                      },
                      child: const Text(AppStrings.addManually),
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
                  subtitle: Text([r.subtitle, r.year?.toString()].where((e) => e != null).join(' - ')),
                  onTap: () {
                    DatabaseService().addItem(widget.category.id, ItemModel(
                      id: '', title: r.title, createdAt: DateTime.now(),
                      posterUrl: r.posterUrl, year: r.year, externalId: r.externalId, mediaType: r.mediaType, genres: r.genres, author: r.author, overview: r.overview,
                    ));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eklendi ?')));
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
