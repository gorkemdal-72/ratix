import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/system_announcement.dart';
import '../../../services/admin_service.dart';

class SystemAnnouncementBanner extends StatefulWidget {
  final AdminService adminService;
  
  const SystemAnnouncementBanner({super.key, required this.adminService});

  @override
  State<SystemAnnouncementBanner> createState() => _SystemAnnouncementBannerState();
}

class _SystemAnnouncementBannerState extends State<SystemAnnouncementBanner> {
  SystemAnnouncement? _announcement;
  bool _isVisible = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncement();
  }

  Future<void> _loadAnnouncement() async {
    final active = await widget.adminService.getActiveAnnouncements();
    if (active.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final latest = SystemAnnouncement.fromJson(active.first);
    final prefs = await SharedPreferences.getInstance();
    final dismissedIds = prefs.getStringList('dismissed_announcements') ?? [];

    if (!dismissedIds.contains(latest.id) && mounted) {
      setState(() {
        _announcement = latest;
        _isVisible = true;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _dismiss() async {
    if (_announcement == null) return;
    final prefs = await SharedPreferences.getInstance();
    final dismissedIds = prefs.getStringList('dismissed_announcements') ?? [];
    dismissedIds.add(_announcement!.id);
    await prefs.setStringList('dismissed_announcements', dismissedIds);
    
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_isVisible || _announcement == null) return const SizedBox.shrink();

    Color bgColor = Colors.blue.shade900;
    IconData icon = Icons.info_outline;

    if (_announcement!.type == 'warning') {
      bgColor = Colors.orange.shade900;
      icon = Icons.warning_amber_rounded;
    } else if (_announcement!.type == 'success') {
      bgColor = Colors.green.shade900;
      icon = Icons.check_circle_outline;
    }

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _announcement!.message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _dismiss,
              tooltip: 'Kapat',
            ),
          ],
        ),
      ),
    );
  }
}
