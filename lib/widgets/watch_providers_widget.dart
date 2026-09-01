import 'package:flutter/material.dart';
import '../../services/search_service.dart';

class WatchProvidersWidget extends StatelessWidget {
  final String mediaType;
  final String externalId;

  const WatchProvidersWidget({super.key, required this.mediaType, required this.externalId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SearchService.instance.getWatchProviders(mediaType, externalId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        
        final providers = snapshot.data;
        if (providers == null || providers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nereden İzlenir?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: providers.map((p) => Tooltip(
                  message: p['name'],
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      p['logo_path'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.error),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
