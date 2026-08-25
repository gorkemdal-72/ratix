import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/social_service.dart';
import '../../models/item_model.dart';
import '../../models/category_model.dart';
import '../../services/database_service.dart';
import '../../core/app_strings.dart';

class CreatePostScreen extends StatefulWidget {
  final ItemModel? preSelectedItem;
  const CreatePostScreen({super.key, this.preSelectedItem});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  List<ItemModel> _userItems = [];
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  ItemModel? _selectedItem;
  bool _isLoadingItems = true;
  bool _isSubmitting = false;
  String _visibility = 'public'; // 'public' veya 'followers_only'

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedItem != null) {
      _selectedItem = widget.preSelectedItem;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dbService = DatabaseService();
      final cats = await dbService.fetchCategories();
      
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      
      final res = await Supabase.instance.client
          .from('items')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
          
      final items = (res as List).map((row) => ItemModel.fromMap(row, row['id'])).toList();
      if (mounted) {
        setState(() {
          _categories = cats;
          _userItems = items;
          if (cats.isNotEmpty) _selectedCategory = cats.first;
          _isLoadingItems = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  void _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir içerik yazın veya bir öge seçin.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await context.read<SocialService>().createPost(
        content: content,
        itemId: _selectedItem?.id,
        visibility: _visibility,
      );
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showItemSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (ctx, scrollController) {
                return _ItemSelectionBottomSheet(
                  items: _userItems,
                  categories: _categories,
                  initialCategory: _selectedCategory,
                  scrollController: scrollController,
                  onItemSelected: (item) {
                    setState(() => _selectedItem = item);
                    Navigator.pop(ctx);
                  },
                );
              },
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.newPost),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(AppStrings.share, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: AppStrings.postPlaceholder,
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.visibility, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(AppStrings.whoCanSee, style: const TextStyle(color: Colors.grey)),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _visibility,
                      isDense: true,
                      items: [
                        DropdownMenuItem(value: 'public', child: Text(AppStrings.publicVisibility)),
                        DropdownMenuItem(value: 'followers_only', child: Text(AppStrings.followersOnlyVisibility)),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _visibility = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add_link),
              title: Text(_selectedItem == null ? AppStrings.attachMedia : AppStrings.changeMedia),
              trailing: _selectedItem != null
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedItem = null),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isLoadingItems ? null : _showItemSelectionSheet,
            ),
            if (_selectedItem != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (_selectedItem!.posterUrl != null && _selectedItem!.posterUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(_selectedItem!.posterUrl!, width: 48, height: 72, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 48,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.movie, size: 24),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedItem!.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${AppStrings.rating}: ${_selectedItem!.rating}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemSelectionBottomSheet extends StatefulWidget {
  final List<ItemModel> items;
  final List<CategoryModel> categories;
  final CategoryModel? initialCategory;
  final ScrollController scrollController;
  final Function(ItemModel) onItemSelected;

  const _ItemSelectionBottomSheet({
    required this.items,
    required this.categories,
    required this.initialCategory,
    required this.scrollController,
    required this.onItemSelected,
  });

  @override
  State<_ItemSelectionBottomSheet> createState() => _ItemSelectionBottomSheetState();
}

class _ItemSelectionBottomSheetState extends State<_ItemSelectionBottomSheet> {
  late CategoryModel? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    List<ItemModel> filteredItems = widget.items;
    
    if (_selectedCategory != null) {
      filteredItems = filteredItems.where((i) => i.categoryId == _selectedCategory!.id).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((i) => i.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(AppStrings.selectItem, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        
        // Kategori Chipleri
        if (widget.categories.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.categories.length + 1, // +1 for "Tümü"
              itemBuilder: (ctx, i) {
                final isAll = i == 0;
                final cat = isAll ? null : widget.categories[i - 1];
                final isSelected = _selectedCategory == cat;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(isAll ? AppStrings.statusAll : '${cat!.icon} ${cat.name}'),
                    selected: isSelected,
                    onSelected: (v) => setState(() => _selectedCategory = cat),
                    selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                );
              },
            ),
          ),
        
        // Arama Kutusu
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: AppStrings.searchItems,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),
        ),
        
        const Divider(height: 1),
        
        // Liste
        if (filteredItems.isEmpty)
          Expanded(child: Center(child: Text(AppStrings.noSearchResult)))
        else
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: filteredItems.length,
              itemBuilder: (ctx, index) {
                final item = filteredItems[index];
                final cat = widget.categories.where((c) => c.id == item.categoryId).firstOrNull;
                
                return ListTile(
                  leading: item.posterUrl != null && item.posterUrl!.isNotEmpty
                      ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(item.posterUrl!, width: 40, height: 60, fit: BoxFit.cover))
                      : Container(
                          width: 40, height: 60,
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Center(child: Text(cat?.icon ?? '🎬', style: const TextStyle(fontSize: 20))),
                        ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${cat?.name ?? AppStrings.noCategory} • ${AppStrings.rating}: ${item.rating}'),
                  onTap: () => widget.onItemSelected(item),
                );
              },
            ),
          ),
      ],
    );
  }
}
