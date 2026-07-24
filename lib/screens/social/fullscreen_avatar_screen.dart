import 'dart:io';
import 'package:flutter/material.dart';

class FullscreenAvatarScreen extends StatelessWidget {
  final String? avatarUrl;
  final File? imageFile;
  final String heroTag;

  const FullscreenAvatarScreen({
    super.key,
    this.avatarUrl,
    this.imageFile,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider? imageProvider = imageFile != null
        ? FileImage(imageFile!) as ImageProvider
        : avatarUrl != null
            ? NetworkImage(avatarUrl!) as ImageProvider
            : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Interactive Viewer for Pinch-to-Zoom
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Hero(
                tag: heroTag,
                child: imageProvider != null
                    ? Image(
                        image: imageProvider,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : const Icon(
                        Icons.person,
                        size: 200,
                        color: Colors.white24,
                      ),
              ),
            ),
          ),
          // Close button overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
