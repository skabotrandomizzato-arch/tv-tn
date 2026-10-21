import 'package:flutter/material.dart';

import '../models.dart';
import '../services/radio_player.dart';
import '../widgets/common.dart';

class RadioScreen extends StatefulWidget {
  final List<RadioStation> stations;
  const RadioScreen({super.key, required this.stations});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  static const _all = 'Toutes';
  String _category = _all;

  @override
  Widget build(BuildContext context) {
    final cats = [_all, ...{for (final s in widget.stations) s.category}];
    final list = _category == _all
        ? widget.stations
        : widget.stations.where((s) => s.category == _category).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Radios')),
      body: Column(
        children: [
          CategoryChips(
            categories: cats,
            selected: _category,
            onSelected: (c) => setState(() => _category = c),
          ),
          const SizedBox(height: 4),
          Expanded(child: RadioList(stations: list)),
        ],
      ),
    );
  }
}

class RadioList extends StatelessWidget {
  final List<RadioStation> stations;
  final bool shrinkWrap;
  const RadioList({super.key, required this.stations, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context) {
    final player = RadioPlayer.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([player.current, player.playing, player.loading]),
      builder: (context, _) => ListView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: stations.length,
        itemBuilder: (context, i) {
          final s = stations[i];
          final isCurrent = player.current.value?.id == s.id;
          final scheme = Theme.of(context).colorScheme;
          Widget trailingIcon;
          if (isCurrent && player.loading.value) {
            trailingIcon = const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5));
          } else if (isCurrent && player.playing.value) {
            trailingIcon = Icon(Icons.graphic_eq_rounded, color: scheme.primary);
          } else {
            trailingIcon = const Icon(Icons.play_circle_outline_rounded);
          }
          return ListTile(
            selected: isCurrent,
            leading: ChannelBadge(name: s.name, color: s.color, size: 46),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(s.category),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FavoriteButton(favKey: s.favKey),
                SizedBox(width: 32, child: Center(child: trailingIcon)),
              ],
            ),
            onTap: () => isCurrent ? player.toggle() : player.play(s),
          );
        },
      ),
    );
  }
}

/// Bar above the bottom navigation while a radio is selected.
class MiniRadioBar extends StatelessWidget {
  const MiniRadioBar({super.key});

  @override
  Widget build(BuildContext context) {
    final player = RadioPlayer.instance;
    return ListenableBuilder(
      listenable: Listenable.merge(
          [player.current, player.playing, player.loading, player.error]),
      builder: (context, _) {
        final s = player.current.value;
        if (s == null) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final status = player.error.value
            ? 'Flux indisponible'
            : player.loading.value
                ? 'Connexion…'
                : player.playing.value
                    ? 'En direct'
                    : 'En pause';
        return Material(
          color: scheme.surfaceContainerHighest,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  ChannelBadge(name: s.name, color: s.color, size: 40, radius: 10),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(status,
                            style: TextStyle(
                                fontSize: 12,
                                color: player.error.value
                                    ? scheme.error
                                    : scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    icon: Icon(player.playing.value || player.loading.value
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                    onPressed: player.toggle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: player.stop,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
