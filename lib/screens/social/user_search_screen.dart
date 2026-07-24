import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'social_profile_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  Timer? _debounce;
  String _currentQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _searchUsers(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      _currentQuery = '';
      if (mounted) setState(() { _results = []; _isLoading = false; });
      return;
    }
    
    _currentQuery = query;
    if (mounted) setState(() => _isLoading = true);
    
    try {
      final res = await Supabase.instance.client
          .from('user_social_profiles_view')
          .select()
          .ilike('username', '%${query.trim()}%')
          .limit(20);
          
      if (_currentQuery != query) return;
          
      if (mounted) {
        setState(() {
          _results = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _currentQuery == query) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Kullanıcı adı ara...',
            border: InputBorder.none,
          ),
          onChanged: _searchUsers,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _searchUsers('');
            },
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty && _searchController.text.isNotEmpty
              ? const Center(child: Text('Kullanıcı bulunamadı.'))
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                        child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(user['username'] ?? 'user', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user['display_name'] ?? ''),
                      onTap: () {
                        // Profile git
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => SocialProfileScreen(userId: user['id']),
                        ));
                      },
                    );
                  },
                ),
    );
  }
}
