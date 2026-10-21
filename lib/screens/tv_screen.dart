import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets/common.dart';
import 'player_screen.dart';

class TvScreen extends StatefulWidget {
  final List<TvChannel> channels;
  const TvScreen({super.key, required this.channels});

  @override
  State<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends State<TvScreen> {
  static const _all = 'Toutes';
  String _category = _all;
  String _query = '';
  bool _searching = false;

  @override
  Widget build(BuildContext context) {
    final cats = [_all, ...{for (final c in widget.channels) c.category}];
    final list = widget.channels.where((c) {
      if (_category != _all && c.category != _category) return false;
      return _query.isEmpty ||
          c.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: 'Rechercher une chaîne', border: InputBorder.none),
                onChanged: (v) => setState(() => _query = v),
              )
            : const _Brand(),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              _query = '';
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          CategoryChips(
            categories: cats,
            selected: _category,
            onSelected: (c) => setState(() => _category = c),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? const EmptyState(
                    icon: Icons.tv_off_rounded, text: 'Aucune chaîne trouvée')
                : TvGrid(channels: list, allChannels: widget.channels),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFE11D2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.live_tv_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        const Text('Tounsi Live',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class TvGrid extends StatelessWidget {
  final List<TvChannel> channels;
  final List<TvChannel> allChannels;
  final bool shrinkWrap;

  const TvGrid({
    super.key,
    required this.channels,
    required this.allChannels,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: width > 900 ? 5 : width > 600 ? 3 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: channels.length,
      itemBuilder: (context, i) => _TvCard(
        channel: channels[i],
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              PlayerScreen(channel: channels[i], channels: allChannels),
        )),
      ),
    );
  }
}

class _TvCard extends StatelessWidget {
  final TvChannel channel;
  final VoidCallback onTap;
  const _TvCard({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChannelBadge(name: channel.name, color: channel.color),
                  const Spacer(),
                  Text(channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const LiveDot(),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(channel.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: FavoriteButton(
                  favKey: channel.favKey, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
