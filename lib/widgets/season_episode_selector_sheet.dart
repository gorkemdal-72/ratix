import 'package:flutter/material.dart';
import '../services/search_service.dart';

class SeasonEpisodeSelectorSheet extends StatefulWidget {
  final SearchResult tvResult;
  final Map<String, dynamic>? initialSeasonsData;

  const SeasonEpisodeSelectorSheet({
    super.key,
    required this.tvResult,
    this.initialSeasonsData,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required SearchResult tvResult,
    Map<String, dynamic>? initialSeasonsData,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SeasonEpisodeSelectorSheet(
        tvResult: tvResult,
        initialSeasonsData: initialSeasonsData,
      ),
    );
  }

  @override
  State<SeasonEpisodeSelectorSheet> createState() => _SeasonEpisodeSelectorSheetState();
}

class _SeasonEpisodeSelectorSheetState extends State<SeasonEpisodeSelectorSheet> {
  bool _isLoadingDetails = true;
  TvShowDetails? _tvDetails;

  // Sezon Numarası -> (Bölüm Numaraları Set'i)
  final Map<int, Set<int>> _selectedEpisodes = {};
  
  // Cache fetched episodes for seasons: SeasonNum -> List<TvEpisodeInfo>
  final Map<int, List<TvEpisodeInfo>> _seasonEpisodesCache = {};
  final Set<int> _loadingSeasons = {};
  final Set<int> _expandedSeasons = {};

  bool _isAllSelected = false;

  @override
  void initState() {
    super.initState();
    _loadTvDetails();
  }

  Future<void> _loadTvDetails() async {
    try {
      final details = await SearchService.instance.getTvDetails(widget.tvResult.externalId);
      if (!mounted) return;

      setState(() {
        _tvDetails = details;
        _isLoadingDetails = false;

        if (details != null) {
          // Mevcut veri varsa yükle
          if (widget.initialSeasonsData != null) {
            _isAllSelected = widget.initialSeasonsData!['all_selected'] == true;
            final seasonsMap = widget.initialSeasonsData!['seasons'] as Map<String, dynamic>?;
            if (seasonsMap != null) {
              seasonsMap.forEach((sNumStr, epList) {
                final sNum = int.tryParse(sNumStr);
                if (sNum != null && epList is List) {
                  _selectedEpisodes[sNum] = epList.map((e) => int.parse(e.toString())).toSet();
                }
              });
            }
          } else {
            // Varsayılan olarak tüm diziyi seçili başlat
            _isAllSelected = true;
            _selectedEpisodes.clear();
            for (final season in details.seasons) {
              final sNum = season.seasonNumber;
              final epCount = season.episodeCount;
              _selectedEpisodes[sNum] = List.generate(epCount, (index) => index + 1).toSet();
            }
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  void _selectAll(bool select) {
    if (_tvDetails == null) return;
    setState(() {
      _isAllSelected = select;
      _selectedEpisodes.clear();

      if (select) {
        for (final season in _tvDetails!.seasons) {
          final sNum = season.seasonNumber;
          final epCount = season.episodeCount;
          _selectedEpisodes[sNum] = List.generate(epCount, (index) => index + 1).toSet();
        }
      }
    });
  }

  void _toggleSeason(int seasonNum, int totalEpCount, bool select) {
    if (_tvDetails == null) return;
    setState(() {
      if (select) {
        // Önceki tüm sezonların tüm bölümlerini de otomatik seç
        for (final season in _tvDetails!.seasons) {
          if (season.seasonNumber <= seasonNum) {
            _selectedEpisodes[season.seasonNumber] =
                List.generate(season.episodeCount, (index) => index + 1).toSet();
          }
        }
      } else {
        _selectedEpisodes[seasonNum] = {};
      }
      _checkAllSelectedStatus();
    });
  }

  void _toggleEpisode(int seasonNum, int epNum, int totalEpCount, bool select) {
    if (_tvDetails == null) return;
    setState(() {
      _selectedEpisodes.putIfAbsent(seasonNum, () => {});
      if (select) {
        // 1. Önceki tüm sezonların tüm bölümlerini otomatik seç
        for (final season in _tvDetails!.seasons) {
          if (season.seasonNumber < seasonNum) {
            _selectedEpisodes[season.seasonNumber] =
                List.generate(season.episodeCount, (index) => index + 1).toSet();
          }
        }
        // 2. Mevcut sezonun 1. bölümünden bu bölüme (epNum) kadar olan tüm bölümleri otomatik seç
        for (int i = 1; i <= epNum; i++) {
          _selectedEpisodes[seasonNum]!.add(i);
        }
      } else {
        _selectedEpisodes[seasonNum]!.remove(epNum);
      }
      _checkAllSelectedStatus();
    });
  }

  void _checkAllSelectedStatus() {
    if (_tvDetails == null) return;
    bool all = true;
    for (final season in _tvDetails!.seasons) {
      final sNum = season.seasonNumber;
      final selectedCount = _selectedEpisodes[sNum]?.length ?? 0;
      if (selectedCount < season.episodeCount) {
        all = false;
        break;
      }
    }
    _isAllSelected = all;
  }

  Future<void> _fetchSeasonEpisodes(int seasonNum) async {
    if (_seasonEpisodesCache.containsKey(seasonNum) || _loadingSeasons.contains(seasonNum)) return;

    _loadingSeasons.add(seasonNum);
    if (mounted) setState(() {});

    final episodes = await SearchService.instance.getTvSeasonEpisodes(widget.tvResult.externalId, seasonNum);

    if (!mounted) return;
    setState(() {
      _seasonEpisodesCache[seasonNum] = episodes;
      _loadingSeasons.remove(seasonNum);
    });
  }

  int _calculateTotalSelectedEpisodes() {
    int count = 0;
    _selectedEpisodes.forEach((sNum, epSet) {
      count += epSet.length;
    });
    return count;
  }

  int _calculateTotalRuntime() {
    final avgRuntime = _tvDetails?.avgEpisodeRuntime ?? 45;
    final totalEp = _calculateTotalSelectedEpisodes();
    return totalEp * avgRuntime;
  }

  void _onConfirm() {
    if (_tvDetails == null) return;

    final selectedEpCount = _calculateTotalSelectedEpisodes();
    final calculatedRuntime = _calculateTotalRuntime();

    final Map<String, List<int>> seasonsMap = {};
    _selectedEpisodes.forEach((sNum, epSet) {
      if (epSet.isNotEmpty) {
        seasonsMap[sNum.toString()] = epSet.toList()..sort();
      }
    });

    final result = {
      'all_selected': _isAllSelected,
      'total_seasons': _tvDetails!.numberOfSeasons,
      'total_episodes': _tvDetails!.numberOfEpisodes,
      'selected_episodes_count': selectedEpCount,
      'calculated_runtime': calculatedRuntime,
      'seasons': seasonsMap,
    };

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    const primaryGreen = Color(0xFF10B981); // Yüksek kontrastlı canlı zümrüt yeşili

    return Container(
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ─── SÜRÜKLEMA ÇUBUĞU ───
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // ─── BAŞLIK & DİZİ ÖZETİ ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (widget.tvResult.posterUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.tvResult.posterUrl!,
                      width: 54,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.tv, size: 40),
                    ),
                  )
                else
                  Container(
                    width: 54,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tv, color: primaryGreen),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tvResult.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (_isLoadingDetails)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen),
                        )
                      else if (_tvDetails != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: primaryGreen.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${_tvDetails!.numberOfSeasons} Sezon • ${_tvDetails!.numberOfEpisodes} Bölüm • Ortalama ${_tvDetails!.avgEpisodeRuntime} dk',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // ─── İÇERİK (LİSTE) ───
          Expanded(
            child: _isLoadingDetails
                ? const Center(child: CircularProgressIndicator(color: primaryGreen))
                : _tvDetails == null
                    ? const Center(child: Text('Sezon detayları yüklenemedi.'))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          // ─── TÜM DİZİYİ SEÇ (MASTER CHECKBOX) ───
                          Container(
                            decoration: BoxDecoration(
                              color: primaryGreen.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryGreen.withValues(alpha: 0.25)),
                            ),
                            child: CheckboxListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              title: Text(
                                'Tüm Diziyi Seç (${_tvDetails!.numberOfEpisodes} Bölüm)',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text('Tüm sezon ve bölümler listeye eklenir'),
                              value: _isAllSelected,
                              activeColor: primaryGreen,
                              onChanged: (val) {
                                _selectAll(val ?? false);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ─── SEZONLAR LİSTESİ ───
                          ..._tvDetails!.seasons.map((season) {
                            final sNum = season.seasonNumber;
                            final epCount = season.episodeCount;
                            final selectedSet = _selectedEpisodes[sNum] ?? {};
                            final selectedCount = selectedSet.length;
                            final isSeasonAllSelected = selectedCount == epCount && epCount > 0;
                            final isSeasonPartial = selectedCount > 0 && selectedCount < epCount;
                            final isExpanded = _expandedSeasons.contains(sNum);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 0,
                              color: isSeasonAllSelected || isExpanded
                                  ? primaryGreen.withValues(alpha: 0.1)
                                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSeasonAllSelected || isExpanded
                                      ? primaryGreen.withValues(alpha: 0.5)
                                      : Colors.transparent,
                                ),
                              ),
                              child: ExpansionTile(
                                key: PageStorageKey('season_$sNum'),
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    if (expanded) {
                                      _expandedSeasons.add(sNum);
                                      _fetchSeasonEpisodes(sNum);
                                    } else {
                                      _expandedSeasons.remove(sNum);
                                    }
                                  });
                                },
                                leading: Checkbox(
                                  value: isSeasonAllSelected
                                      ? true
                                      : (isSeasonPartial ? null : false),
                                  tristate: true,
                                  activeColor: primaryGreen,
                                  onChanged: (val) {
                                    _toggleSeason(sNum, epCount, val == true);
                                  },
                                ),
                                title: Text(
                                  season.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '$selectedCount / $epCount Bölüm Seçildi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selectedCount > 0 ? primaryGreen : Colors.grey,
                                  ),
                                ),
                                children: !isExpanded
                                    ? const []
                                    : [
                                        if (_loadingSeasons.contains(sNum))
                                          const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen)),
                                          )
                                        else if (_seasonEpisodesCache.containsKey(sNum))
                                          ..._seasonEpisodesCache[sNum]!.map((ep) {
                                            final isEpSelected = selectedSet.contains(ep.episodeNumber);
                                            return CheckboxListTile(
                                              dense: true,
                                              title: Text('${ep.episodeNumber}. ${ep.name}'),
                                              subtitle: ep.runtime != null ? Text('${ep.runtime} dk') : null,
                                              value: isEpSelected,
                                              activeColor: primaryGreen,
                                              onChanged: (val) {
                                                _toggleEpisode(sNum, ep.episodeNumber, epCount, val == true);
                                              },
                                            );
                                          })
                                        else
                                          ...List.generate(epCount, (idx) {
                                            final epNum = idx + 1;
                                            final isEpSelected = selectedSet.contains(epNum);
                                            return CheckboxListTile(
                                              dense: true,
                                              title: Text('$epNum. Bölüm'),
                                              value: isEpSelected,
                                              activeColor: primaryGreen,
                                              onChanged: (val) {
                                                _toggleEpisode(sNum, epNum, epCount, val == true);
                                              },
                                            );
                                          }),
                                      ],
                              ),
                            );
                          }),
                        ],
                      ),
          ),

          // ─── ALT SABİT ONAY BUTONU ───
          if (!_isLoadingDetails && _tvDetails != null) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.scaffoldBackgroundColor,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_calculateTotalSelectedEpisodes()} Bölüm Seçildi',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                          Text(
                            'Toplam ~${_calculateTotalRuntime()} dk (${(_calculateTotalRuntime() / 60).toStringAsFixed(1)} saat)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _onConfirm,
                      icon: const Icon(Icons.check),
                      label: Text(
                        _calculateTotalSelectedEpisodes() > 0 ? 'Seçimi Ekle' : 'Devam Et', 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
