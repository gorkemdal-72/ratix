import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/item_model.dart';
import '../../core/app_strings.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isLoading = true;
  List<ItemModel> _upcomingItems = [];
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _fetchUpcoming();
  }

  Future<void> _fetchUpcoming() async {
    setState(() => _isLoading = true);
    final items = await _dbService.getUpcomingItems();
    if (mounted) {
      setState(() {
        _upcomingItems = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.isEn ? 'Upcoming / Calendar' : 'Yaklaşanlar / Takvim'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _upcomingItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.isEn ? 'No upcoming releases.' : 'Yaklaşan hiçbir içerik yok.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchUpcoming,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _upcomingItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _upcomingItems[index];
                      final airDate = item.nextAirDate ?? DateTime.now();
                      final daysLeft = airDate.difference(DateTime.now()).inDays;
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                          children: [
                            if (item.posterUrl != null)
                              CachedNetworkImage(
                                imageUrl: item.posterUrl!,
                                width: 80,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            else
                              Container(
                                width: 80,
                                height: 120,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                child: const Icon(Icons.movie),
                              ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMMM yyyy').format(airDate),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: daysLeft <= 7
                                            ? Colors.red.withValues(alpha: 0.1)
                                            : Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        daysLeft == 0 ? 'Bugün!' : '$daysLeft gün kaldı',
                                        style: TextStyle(
                                          color: daysLeft <= 7 ? Colors.red : Colors.blue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
