import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../core/app_theme.dart';
import '../social/social_profile_screen.dart';
import 'package:intl/intl.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Moderasyon Paneli'),
          bottom: const TabBar(
            isScrollable: false,
            labelPadding: EdgeInsets.symmetric(horizontal: 4.0),
            tabs: [
              Tab(text: 'Bekleyenler', icon: Icon(Icons.report_problem)),
              Tab(text: 'Geçmiş', icon: Icon(Icons.history)),
              Tab(text: 'Son Uyarılar', icon: Icon(Icons.warning_amber_rounded)),
              Tab(text: 'Duyurular', icon: Icon(Icons.campaign)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ReportsTab(),
            _ResolvedReportsTab(),
            _WarningsTab(),
            _AnnouncementsTab(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// ŞİKAYETLER SEKMESİ
// ═══════════════════════════════════════════════
class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final service = context.read<AdminService>();
    final reports = await service.getPendingReports();
    if (mounted) {
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAction(Map<String, dynamic> report, String actionType) async {
    final service = context.read<AdminService>();
    final reportedUserId = report['reported_user_id'];
    final reporterId = report['reporter_id'];
    final reportId = report['id'];

    if (reportedUserId == null) return;

    bool success = false;
    
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(child: CircularProgressIndicator())
    );

    try {
      if (actionType == 'ban') {
        success = await service.banUser(reportedUserId, report['reason'] ?? 'Şikayet üzerine');
        if (success) await service.resolveReport(reportId, reporterId);
      } else if (actionType == 'mute') {
        success = await service.muteUser(reportedUserId, const Duration(days: 1), report['reason'] ?? 'Şikayet üzerine');
        if (success) await service.resolveReport(reportId, reporterId);
      } else if (actionType == 'warn') {
        success = await service.sendWarning(reportedUserId, report['reason'] ?? 'Kuralları ihlal ettiniz');
        if (success) await service.resolveReport(reportId, reporterId);
      } else if (actionType == 'dismiss') {
        success = await service.dismissReport(reportId, reporterId);
      }
    } finally {
      if (mounted) Navigator.pop(context); // close loading
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aksiyon alındı.')));
      _loadReports();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem başarısız (Yetkiniz olmayabilir)')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reports.isEmpty) {
      return const Center(child: Text('Bekleyen şikayet yok! 🎊'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final reporter = report['reporter'];
    final reported = report['reported'];
    
    DateTime parsedDate = DateTime.now();
    try {
      if (report['created_at'] != null) {
        parsedDate = DateTime.parse(report['created_at'].toString());
      }
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sebep: ${report['reason']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(DateFormat.yMMMd('tr_TR').format(parsedDate), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            if (report['details'] != null && report['details'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Detay: ${report['details']}'),
            ],
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                const Text('Şikayet Edilen: '),
                GestureDetector(
                  onTap: () {
                    if (report['reported_user_id'] != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SocialProfileScreen(userId: report['reported_user_id'])));
                    }
                  },
                  child: Text(reported?['display_name'] ?? reported?['username'] ?? 'Bilinmiyor', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('Şikayet Eden: '),
                GestureDetector(
                  onTap: () {
                    if (report['reporter_id'] != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SocialProfileScreen(userId: report['reporter_id'])));
                    }
                  },
                  child: Text(reporter?['display_name'] ?? reporter?['username'] ?? 'Bilinmiyor', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (report['post_id'] != null) Text('Gönderi ID: ${report['post_id']}'),
            if (report['comment_id'] != null) Text('Yorum ID: ${report['comment_id']}'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handleAction(report, 'ban'),
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('Banla'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  onPressed: () => _handleAction(report, 'mute'),
                  icon: const Icon(Icons.volume_off, size: 18),
                  label: const Text('24s Sustur'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  onPressed: () => _handleAction(report, 'warn'),
                  icon: const Icon(Icons.warning, size: 18),
                  label: const Text('Uyarı Gönder'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                ),
                OutlinedButton.icon(
                  onPressed: () => _handleAction(report, 'dismiss'),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('İhlal Yok Kapat'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// GEÇMİŞ ŞİKAYETLER SEKMESİ
// ═══════════════════════════════════════════════
class _ResolvedReportsTab extends StatefulWidget {
  const _ResolvedReportsTab();

  @override
  State<_ResolvedReportsTab> createState() => _ResolvedReportsTabState();
}

class _ResolvedReportsTabState extends State<_ResolvedReportsTab> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final service = context.read<AdminService>();
    final reports = await service.getResolvedReports();
    if (mounted) {
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reports.isEmpty) {
      return const Center(child: Text('Geçmiş şikayet kaydı bulunamadı.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        final reporter = report['reporter'];
        final reported = report['reported'];
        final resolver = report['resolver'];
        
        DateTime parsedDate = DateTime.now();
        try {
          if (report['resolved_at'] != null) {
            parsedDate = DateTime.parse(report['resolved_at'].toString());
          }
        } catch (_) {}

        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Durum: ${report['status']}', style: TextStyle(fontWeight: FontWeight.bold, color: report['status'] == 'dismissed' ? Colors.grey : Colors.green)),
                    Text(DateFormat.yMMMd('tr_TR').format(parsedDate), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Sebep: ${report['reason']}'),
                if (report['details'] != null && report['details'].toString().isNotEmpty)
                  Text('Detay: ${report['details']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                const Divider(),
                Text('Şikayet Eden: ${reporter?['username'] ?? 'Bilinmiyor'}'),
                Text('Şikayet Edilen: ${reported?['username'] ?? 'Bilinmiyor'}'),
                Text('Çözen Admin: ${resolver?['username'] ?? 'Bilinmiyor'}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// UYARILAR SEKMESİ
// ═══════════════════════════════════════════════
class _WarningsTab extends StatefulWidget {
  const _WarningsTab();

  @override
  State<_WarningsTab> createState() => _WarningsTabState();
}

class _WarningsTabState extends State<_WarningsTab> {
  List<Map<String, dynamic>> _warnings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWarnings();
  }

  Future<void> _loadWarnings() async {
    setState(() => _isLoading = true);
    final service = context.read<AdminService>();
    final warnings = await service.getAllWarnings();
    if (mounted) {
      setState(() {
        _warnings = warnings;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_warnings.isEmpty) return const Center(child: Text('Hiç uyarı bulunamadı.'));

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      itemCount: _warnings.length,
      itemBuilder: (context, index) {
        final w = _warnings[index];
        final target = w['target_user'];
        final admin = w['admin_user'];
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
          child: ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            title: Text(w['reason'] ?? 'Belirtilmemiş'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Kullanıcı: ${target?['username'] ?? 'Bilinmiyor'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Admin: ${admin?['username'] ?? 'Bilinmiyor'}'),
              ],
            ),
            trailing: Text(
              w['created_at'] != null ? DateFormat.yMMMd('tr_TR').format(DateTime.parse(w['created_at'])) : '',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// DUYURULAR SEKMESİ
// ═══════════════════════════════════════════════
class _AnnouncementsTab extends StatefulWidget {
  const _AnnouncementsTab();

  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    final service = context.read<AdminService>();
    final announcements = await service.getActiveAnnouncements();
    if (mounted) {
      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });
    }
  }

  Future<void> _createAnnouncement() async {
    final textCtrl = TextEditingController();
    String selectedType = 'info';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Duyuru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Duyuru metni...'),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'info', child: Text('Bilgi')),
                  DropdownMenuItem(value: 'warning', child: Text('Uyarı')),
                  DropdownMenuItem(value: 'update', child: Text('Güncelleme')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedType = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yayınla'),
            ),
          ],
        ),
      ),
    );

    if (result == true && textCtrl.text.isNotEmpty) {
      final service = context.read<AdminService>();
      await service.createAnnouncement(textCtrl.text, type: selectedType);
      _loadAnnouncements();
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    final service = context.read<AdminService>();
    await service.deleteAnnouncement(id);
    _loadAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _createAnnouncement,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? const Center(child: Text('Aktif duyuru yok.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  itemCount: _announcements.length,
                  itemBuilder: (context, index) {
                    final a = _announcements[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                      child: ListTile(
                        title: Text(a['message'] ?? ''),
                        subtitle: Text('Tür: ${a['type']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAnnouncement(a['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
