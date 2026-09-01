import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/app_strings.dart';

class SpoilerShield extends StatefulWidget {
  final Widget child;
  final bool isSpoiler;

  const SpoilerShield({super.key, required this.child, this.isSpoiler = false});

  @override
  State<SpoilerShield> createState() => _SpoilerShieldState();
}

class _SpoilerShieldState extends State<SpoilerShield> {
  bool _isHidden = true;

  @override
  void initState() {
    super.initState();
    _isHidden = widget.isSpoiler;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpoiler || !_isHidden) {
      return widget.child;
    }

    return GestureDetector(
      onTap: () => setState(() => _isHidden = false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: widget.child,
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.1),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_off, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.isEn ? 'Spoiler - Tap to reveal' : 'Spoiler - Görmek için dokun',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
