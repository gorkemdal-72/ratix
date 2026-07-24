import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/social_service.dart';
import '../../services/admin_service.dart';
import '../../models/post_model.dart';
import 'widgets/post_card.dart';
import 'widgets/system_announcement_banner.dart';
import 'create_post_screen.dart';
import 'user_search_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sosyal Akış'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const UserSearchScreen(),
              ));
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Takip Ettiklerin'),
            Tab(text: 'Keşfet'),
          ],
        ),
      ),
      body: Column(
        children: [
          SystemAnnouncementBanner(adminService: _adminService),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _FeedTab(isDiscover: false),
                _FeedTab(isDiscover: true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
          if (result == true) {
            // İsteğe bağlı olarak burada listeyi yeniletebiliriz.
          }
        },
        child: const Icon(Icons.add_comment),
      ),
    );
  }
}

class _FeedTab extends StatefulWidget {
  final bool isDiscover;
  const _FeedTab({required this.isDiscover});

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<SocialService>();
      final posts = widget.isDiscover 
          ? await service.getDiscoverPosts() 
          : await service.getTimeline();
      if (mounted) setState(() => _posts = posts);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return Center(
        child: Text(widget.isDiscover ? 'Henüz gönderi yok.' : 'Takip ettiğiniz kişilerin gönderileri burada görünür.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return PostCard(post: _posts[index], onDelete: _loadPosts);
        },
      ),
    );
  }
}
