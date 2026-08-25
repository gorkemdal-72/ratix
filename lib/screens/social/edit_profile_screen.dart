import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/avatar_upload_widget.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _badgeEmojiCtrl;
  bool _isLoading = false;
  String? _errorMessage;
  File? _selectedImageFile;

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController(text: widget.profile.displayName);
    _usernameCtrl = TextEditingController(text: widget.profile.username);
    _bioCtrl = TextEditingController(text: widget.profile.bio);
    _badgeEmojiCtrl = TextEditingController(text: widget.profile.badgeEmoji ?? '');
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _badgeEmojiCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newUsername = _usernameCtrl.text.trim();
    final newDisplayName = _displayNameCtrl.text.trim();
    final newBio = _bioCtrl.text.trim();
    final newBadgeEmoji = _badgeEmojiCtrl.text.trim();

    try {
      // Eğer kullanıcı adını değiştirdiyse, başkası almış mı kontrol et
      if (newUsername != widget.profile.username) {
        final isAvailable = await context.read<AuthService>().checkUsernameAvailable(newUsername);
        if (!isAvailable) {
          setState(() {
            _errorMessage = 'Bu kullanıcı adı zaten alınmış. Lütfen başka bir tane seçin.';
            _isLoading = false;
          });
          return;
        }
      }

      String? finalAvatarUrl = widget.profile.avatarUrl;

      if (_selectedImageFile != null) {
        final bytes = await _selectedImageFile!.readAsBytes();
        final fileExt = _selectedImageFile!.path.split('.').last;
        final fileName = '${widget.profile.id}/avatar.$fileExt';
        
        // Storage'a yükle (upsert: true ile üzerine yazar)
        await Supabase.instance.client.storage.from('avatars').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

        final rawUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
        // Önbelleği aşmak için anlık zaman damgası ekle!
        finalAvatarUrl = '$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}';

        // Auth meta verilerini güncelle
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              'avatar_url': finalAvatarUrl,
              'display_name': newDisplayName,
            }
          ),
        );
      } else {
        // İsim değişmiş olabileceği için auth meta verisini yine de güncelle
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              'display_name': newDisplayName,
            }
          ),
        );
      }

      // Veritabanı tablosunu güncelle
      final updateData = {
        'display_name': newDisplayName,
        'username': newUsername,
        'bio': newBio,
        'avatar_url': finalAvatarUrl,
      };

      if (widget.profile.hasAdminPrivileges) {
        updateData['badge_emoji'] = newBadgeEmoji.isNotEmpty ? newBadgeEmoji : null;
      }

      await Supabase.instance.client.from('users').update(updateData).eq('id', widget.profile.id);

      if (mounted) {
        Navigator.pop(context, true); // True döndürerek sayfanın yenilenmesini sağla
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Profil güncellenirken bir hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
            )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Center(
                    child: AvatarUploadWidget(
                      radius: 44,
                      initialAvatarUrl: widget.profile.avatarUrl,
                      selectedImageFile: _selectedImageFile,
                      onImageSelected: (file) {
                        setState(() {
                          _selectedImageFile = file;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _displayNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Görünen İsim',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Görünen isim boş olamaz.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı Adı (Nick)',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Kullanıcı adı boş olamaz.';
                      if (v.contains(' ')) return 'Kullanıcı adında boşluk olamaz.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Hakkında (Bio)',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                    maxLines: 3,
                  ),
                  if (widget.profile.hasAdminPrivileges) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _badgeEmojiCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Özel Admin Rozeti (Emoji)',
                        hintText: 'Örn: 🦄, 🦇, 🥷 (Boş bırakırsan 👑/🛡️ görünür)',
                        prefixIcon: Icon(Icons.emoji_emotions),
                      ),
                      maxLength: 5,
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Değişiklikleri Kaydet'),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }
}
