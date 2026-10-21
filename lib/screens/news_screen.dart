import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../services/news_service.dart';
import '../widgets/common.dart';

class NewsScreen extends StatefulWidget {
  final List<NewsSource> sources;
  const NewsScreen({super.key, required this.sources});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  static const _all = 'Tout';
  String _selected = _all;
  late Future<List<Article>> _future = _load();

  Future<List<Article>> _load({bool force = false}) {
    if (_selected == _all) {
      return NewsService.fetchAll(widget.sources, force: force);
    }
    final src = widget.sources.firstWhere((s) => s.name == _selected);
    return NewsService.fetch(src, force: force);
  }

  Future<void> _refresh() async {
    final f = _load(force: true);
    setState(() => _future = f);
    await f.catchError((_) => <Article>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actualités')),
      body: Column(
        children: [
          CategoryChips(
            categories: [_all, ...widget.sources.map((s) => s.name)],
            selected: _selected,
            onSelected: (c) => setState(() {
              _selected = c;
              _future = _load();
            }),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: FutureBuilder<List<Article>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data ?? const [];
                if (snap.hasError || items.isEmpty) {
                  return EmptyState(
                    icon: Icons.cloud_off_rounded,
                    text: 'Impossible de charger les actualités',
                    action: FilledButton.tonal(
                        onPressed: _refresh, child: const Text('Réessayer')),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => i == 0 && items[0].imageUrl != null
                        ? _HeroCard(article: items[0])
                        : _ArticleTile(article: items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void _open(Article a) => launchUrl(Uri.parse(a.link), mode: LaunchMode.inAppBrowserView);

String _ago(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

TextDirection _dir(Article a) =>
    a.source.lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;

class _Meta extends StatelessWidget {
  final Article article;
  const _Meta({required this.article});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Text(
      [article.source.name, _ago(article.date)].where((s) => s.isNotEmpty).join(' · '),
      style: TextStyle(fontSize: 12, color: muted),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  final double? width;
  final double height;
  const _Thumb({required this.url, this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    final placeholder = Container(
      width: width,
      height: height,
      color: bg,
      child: const Icon(Icons.article_outlined),
    );
    if (url == null) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(width: width, height: height, color: bg),
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Article article;
  const _HeroCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(article),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Thumb(url: article.imageUrl, height: 190),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Directionality(
                textDirection: _dir(article),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    _Meta(article: article),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  final Article article;
  const _ArticleTile({required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(article),
        child: Directionality(
          textDirection: _dir(article),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(url: article.imageUrl, width: 110, height: 90),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(article.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      _Meta(article: article),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
