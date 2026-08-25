import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/diary_service.dart';
import '../../models/item_model.dart';
import '../../core/app_theme.dart';
import '../../core/app_strings.dart';

class DiaryScreen extends StatefulWidget {
  final String? userId;
  final String? username;
  const DiaryScreen({super.key, this.userId, this.username});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final DiaryService _diaryService = DiaryService();
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  Map<DateTime, List<ItemModel>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMonthData(_focusedDay.year, _focusedDay.month);
  }

  Future<void> _loadMonthData(int year, int month) async {
    setState(() => _isLoading = true);
    final data = await _diaryService.getMonthlyDiary(year, month, userId: widget.userId);
    if (mounted) {
      setState(() {
        _events = data;
        _isLoading = false;
      });
    }
  }

  List<ItemModel> _getEventsForDay(DateTime day) {
    final normalized = DateTime.utc(day.year, day.month, day.day);
    return _events[normalized] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username != null
            ? (AppStrings.isEn ? '@${widget.username}\'s Diary' : '@${widget.username} Günlüğü')
            : AppStrings.diaryTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TableCalendar<ItemModel>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: AppStrings.isEn
                ? const {
                    CalendarFormat.month: 'Month',
                    CalendarFormat.twoWeeks: '2 Weeks',
                    CalendarFormat.week: 'Week',
                  }
                : const {
                    CalendarFormat.month: 'Ay',
                    CalendarFormat.twoWeeks: '2 Hafta',
                    CalendarFormat.week: 'Hafta',
                  },
            locale: AppStrings.isEn ? 'en_US' : 'tr_TR',
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() => _calendarFormat = format);
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadMonthData(focusedDay.year, focusedDay.month);
            },
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: selectedEvents.isEmpty
                  ? Center(
                      child: Text(
                        AppStrings.isEn ? 'No records for this day.' : 'Bu güne ait bir kayıt yok.',
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: selectedEvents.length,
                      itemBuilder: (context, index) {
                        final item = selectedEvents[index];
                        return _buildDiaryItemCard(item);
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiaryItemCard(ItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster veya Kategori İkonu
          if (item.posterUrl != null && item.posterUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(item.posterUrl!, width: 50, height: 75, fit: BoxFit.cover),
            )
          else
            Container(
              width: 50,
              height: 75,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(item.categoryIcon ?? '📌', style: const TextStyle(fontSize: 24)),
              ),
            ),
          const SizedBox(width: 12),
          // İçerik
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.categoryIcon ?? '📌'),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (item.categoryName != null)
                  Text(
                    item.categoryName!,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                const SizedBox(height: 4),
                if (item.rating > 0)
                  Text(
                    '${AppStrings.rating}: ${item.rating}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                if (item.review != null && item.review!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '"${item.review!}"',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
