import 'package:flutter/material.dart';

Color _parseColor(String? hex) {
  final h = (hex ?? '#C8102E').replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

enum StreamType { hls, youtube }

class TvChannel {
  final String id;
  final String name;
  final String category;
  final StreamType type;

  /// Direct HLS url (when type is hls).
  final String? url;

  /// Official YouTube channel id. Used as the main source for youtube
  /// channels and as a fallback for hls ones.
  final String? youtubeChannelId;
  final Color color;

  const TvChannel({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.color,
    this.url,
    this.youtubeChannelId,
  });

  factory TvChannel.fromJson(Map<String, dynamic> j) => TvChannel(
        id: j['id'],
        name: j['name'],
        category: j['category'] ?? 'Autres',
        type: j['type'] == 'youtube' ? StreamType.youtube : StreamType.hls,
        url: j['url'],
        youtubeChannelId: j['youtube'],
        color: _parseColor(j['color']),
      );

  String get favKey => 'tv:$id';
}

class RadioStation {
  final String id;
  final String name;
  final String category;
  final String url;
  final Color color;

  const RadioStation({
    required this.id,
    required this.name,
    required this.category,
    required this.url,
    required this.color,
  });

  factory RadioStation.fromJson(Map<String, dynamic> j) => RadioStation(
        id: j['id'],
        name: j['name'],
        category: j['category'] ?? 'Autres',
        url: j['url'],
        color: _parseColor(j['color']),
      );

  String get favKey => 'radio:$id';
}

class NewsSource {
  final String id;
  final String name;
  final String lang;
  final String url;

  const NewsSource({
    required this.id,
    required this.name,
    required this.lang,
    required this.url,
  });

  factory NewsSource.fromJson(Map<String, dynamic> j) => NewsSource(
        id: j['id'],
        name: j['name'],
        lang: j['lang'] ?? 'fr',
        url: j['url'],
      );
}

class Article {
  final String title;
  final String link;
  final String? imageUrl;
  final DateTime? date;
  final NewsSource source;

  const Article({
    required this.title,
    required this.link,
    required this.source,
    this.imageUrl,
    this.date,
  });
}

class Catalog {
  final List<TvChannel> tv;
  final List<RadioStation> radio;
  final List<NewsSource> news;

  const Catalog({required this.tv, required this.radio, required this.news});

  factory Catalog.fromJson(Map<String, dynamic> j) => Catalog(
        tv: (j['tv'] as List).map((e) => TvChannel.fromJson(e)).toList(),
        radio:
            (j['radio'] as List).map((e) => RadioStation.fromJson(e)).toList(),
        news: (j['news'] as List).map((e) => NewsSource.fromJson(e)).toList(),
      );
}
