import 'package:flutter/material.dart';

import '../models.dart';
import '../services/favorites.dart';
import '../widgets/common.dart';
import 'radio_screen.dart';
import 'tv_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final Catalog catalog;
  const FavoritesScreen({super.key, required this.catalog});

  @override
  Widget build(BuildContext context) {
    final favs = Favorites.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Favoris')),
      body: ListenableBuilder(
        listenable: favs,
        builder: (context, _) {
          final tv = catalog.tv.where((c) => favs.contains(c.favKey)).toList();
          final radio =
              catalog.radio.where((s) => favs.contains(s.favKey)).toList();
          if (tv.isEmpty && radio.isEmpty) {
            return const EmptyState(
              icon: Icons.star_outline_rounded,
              text:
                  'Aucun favori pour le moment.\nTouchez ☆ sur une chaîne ou une radio pour la retrouver ici.',
            );
          }
          return ListView(
            children: [
              if (tv.isNotEmpty) ...[
                const _Header('Chaînes TV'),
                TvGrid(channels: tv, allChannels: catalog.tv, shrinkWrap: true),
              ],
              if (radio.isNotEmpty) ...[
                const _Header('Radios'),
                RadioList(stations: radio, shrinkWrap: true),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
}
