import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/app_theme.dart';
import '../core/app_strings.dart';

class AvatarUploadWidget extends StatefulWidget {
  final double radius;
  final VoidCallback? onUploadComplete;

  const AvatarUploadWidget({
    super.key,
    this.radius = 50,
    this.onUploadComplete,
  });

  @override
  State<AvatarUploadWidget> createState() => _AvatarUploadWidgetState();
}

class _AvatarUploadWidgetState extends State<AvatarUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
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
                // Başlık
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  child: Text(
                    AppStrings.pickSource,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                // Galeri
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text(AppStrings.gallery),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                // Kamera
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text(AppStrings.camera),
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

      setState(() => _isLoading = true);

      User? user = _auth.currentUser;
      if (user != null) {
        Reference ref = _storage.ref().child('profile_images/${user.uid}.jpg');
        
        try {
           UploadTask uploadTask = ref.putFile(File(image.path));
           TaskSnapshot snapshot = await uploadTask;
           String downloadUrl = await snapshot.ref.getDownloadURL();

           await user.updatePhotoURL(downloadUrl);
           await user.reload();
           
           if (mounted) {
             setState(() {});
             if (widget.onUploadComplete != null) widget.onUploadComplete!();
             
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text(AppStrings.photoUpdated)),
             );
           }
        } catch (e) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text(AppStrings.errorUpload)),
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
    User? user = _auth.currentUser;

    return Center(
      child: Stack(
        children: [
          // Avatar ana gövde
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                : CircleAvatar(
                    radius: widget.radius,
                    backgroundColor: Theme.of(context).cardTheme.color,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? Icon(
                            Icons.person_rounded,
                            size: widget.radius * 0.8,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          )
                        : null,
                  ),
          ),
          // Kamera butonu
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
                      color: AppTheme.gradientStart.withOpacity(0.3),
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
