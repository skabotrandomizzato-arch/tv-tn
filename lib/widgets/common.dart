import 'package:flutter/material.dart';

import '../services/favorites.dart';

/// Coloured tile with the channel initials, used instead of logos
/// (no trademarked artwork bundled in the app).
class ChannelBadge extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  final double radius;

  const ChannelBadge({
    super.key,
    required this.name,
    required this.color,
    this.size = 48,
    this.radius = 12,
  });

  String get _initials {
    final words = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !['FM', 'TV'].contains(w.toUpperCase()))
        .toList();
    if (words.isEmpty) return name.substring(0, 1);
    if (words.length == 1) {
      return words.first.length > 2
          ? words.first.substring(0, 2)
          : words.first;
    }
    final last = words[1];
    // "Watania 1" -> "W1"
    return words[0][0] + last[0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.45)!],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.34,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  final String favKey;
  final Color? color;
  const FavoriteButton({super.key, required this.favKey, this.color});

  @override
  Widget build(BuildContext context) {
    final favs = Favorites.instance;
    return ListenableBuilder(
      listenable: favs,
      builder: (context, _) {
        final on = favs.contains(favKey);
        return IconButton(
          tooltip: on ? 'Retirer des favoris' : 'Ajouter aux favoris',
          icon: Icon(on ? Icons.star_rounded : Icons.star_outline_rounded,
              color: on ? Colors.amber : color),
          onPressed: () => favs.toggle(favKey),
        );
      },
    );
  }
}

class LiveDot extends StatelessWidget {
  const LiveDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D2E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('LIVE',
          style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8)),
    );
  }
}

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = categories[i];
          return ChoiceChip(
            label: Text(c),
            selected: c == selected,
            showCheckmark: false,
            onSelected: (_) => onSelected(c),
          );
        },
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const EmptyState(
      {super.key, required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: muted),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center, style: TextStyle(color: muted)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
