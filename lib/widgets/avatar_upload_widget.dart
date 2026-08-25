import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import '../screens/social/fullscreen_avatar_screen.dart';
import '../core/app_theme.dart';
import '../core/app_strings.dart';

class AvatarUploadWidget extends StatefulWidget {
  final double radius;
  final VoidCallback? onUploadComplete;
  final String? initialAvatarUrl;
  final File? selectedImageFile;
  final ValueChanged<File?>? onImageSelected;

  const AvatarUploadWidget({
    super.key,
    this.radius = 50,
    this.onUploadComplete,
    this.initialAvatarUrl,
    this.selectedImageFile,
    this.onImageSelected,
  });

  @override
  State<AvatarUploadWidget> createState() => _AvatarUploadWidgetState();
}

class _AvatarUploadWidgetState extends State<AvatarUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = false;

  Future<void> _showPickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  child: Text(
                    AppStrings.pickSource,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(AppStrings.gallery),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(AppStrings.camera),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: AppTheme.spaceSm),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Fotoğrafı Düzenle',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: 'Fotoğrafı Düzenle',
            aspectRatioLockEnabled: true,
            cropStyle: CropStyle.circle,
          ),
        ],
      );

      if (croppedFile == null) return;

      final finalFile = File(croppedFile.path);

      if (widget.onImageSelected != null) {
        widget.onImageSelected!(finalFile);
        return;
      }

      setState(() => _isLoading = true);

      final User? user = _supabase.auth.currentUser;
      if (user != null) {
        try {
           final file = finalFile;
           final bytes = await file.readAsBytes();
           final fileExt = finalFile.path.split('.').last;
           final fileName = '${user.id}/avatar.$fileExt';
           
           // Upload to Supabase Storage
           await _supabase.storage.from('avatars').uploadBinary(
             fileName, 
             bytes, 
             fileOptions: const FileOptions(upsert: true)
           );
           
           // Get public URL
           final String downloadUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

           // Update user metadata in Supabase Auth
           await _supabase.auth.updateUser(
             UserAttributes(
               data: {
                 'avatar_url': downloadUrl,
                 'display_name': user.userMetadata?['display_name'],
               }
             ),
           );
           
           // Update profile table as well (ignore errors if column doesn't exist)
           try {
             await _supabase.from('users').update({
               'avatar_url': downloadUrl
             }).eq('id', user.id);
           } catch (_) {
             // avatar_url column may not exist in users table yet
           }
           
           if (mounted) {
             setState(() {});
             if (widget.onUploadComplete != null) widget.onUploadComplete!();
             
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(AppStrings.photoUpdated)),
             );
           }
        } catch (e) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('${AppStrings.errorUpload} ($e)')),
             );
           }
        }
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("${AppStrings.errorGeneric}: $e")),
         );
       }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _supabase.auth.currentUser;
    final String? avatarUrl = widget.initialAvatarUrl ?? user?.userMetadata?['avatar_url'];

    final ImageProvider? backgroundImage = widget.selectedImageFile != null
        ? FileImage(widget.selectedImageFile!) as ImageProvider
        : avatarUrl != null
            ? NetworkImage(avatarUrl) as ImageProvider
            : null;

    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            child: _isLoading
                ? CircleAvatar(
                    radius: widget.radius,
                    backgroundColor: Theme.of(context).cardTheme.color,
                    child: SizedBox(
                      width: widget.radius * 0.6,
                      height: widget.radius * 0.6,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      if (backgroundImage != null) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => FullscreenAvatarScreen(
                            avatarUrl: widget.selectedImageFile == null ? avatarUrl : null,
                            imageFile: widget.selectedImageFile,
                            heroTag: 'avatar_${avatarUrl ?? widget.selectedImageFile?.path ?? "placeholder"}',
                          ),
                        ));
                      }
                    },
                    child: Hero(
                      tag: 'avatar_${avatarUrl ?? widget.selectedImageFile?.path ?? "placeholder"}',
                      child: CircleAvatar(
                        radius: widget.radius,
                        backgroundColor: Theme.of(context).cardTheme.color,
                        backgroundImage: backgroundImage,
                        child: backgroundImage == null
                            ? Icon(
                                Icons.person_rounded,
                                size: widget.radius * 0.8,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              )
                            : null,
                      ),
                    ),
                  ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: GestureDetector(
              onTap: _showPickerOptions,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gradientStart.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
