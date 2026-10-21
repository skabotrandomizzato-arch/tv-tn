import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models.dart';

class NewsService {
  static final _cache = <String, List<Article>>{};

  static Future<List<Article>> fetch(NewsSource source,
      {bool force = false}) async {
    if (!force && _cache.containsKey(source.id)) return _cache[source.id]!;
    final res = await http.get(Uri.parse(source.url), headers: {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 14) TounsiLive/1.0'
    }).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final doc = XmlDocument.parse(utf8.decode(res.bodyBytes, allowMalformed: true));
    final items = doc.findAllElements('item').map((e) => _parse(e, source));
    final list = items.whereType<Article>().toList();
    _cache[source.id] = list;
    return list;
  }

  /// All sources merged, newest first. Failing sources are skipped.
  static Future<List<Article>> fetchAll(List<NewsSource> sources,
      {bool force = false}) async {
    final results = await Future.wait(sources.map((s) =>
        fetch(s, force: force).catchError((_) => <Article>[])));
    final all = results.expand((e) => e).toList();
    all.sort((a, b) =>
        (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)));
    return all;
  }

  static Article? _parse(XmlElement e, NewsSource source) {
    String? text(String name) =>
        e.findElements(name).firstOrNull?.innerText.trim();
    final title = _clean(text('title') ?? '');
    final link = text('link') ?? '';
    if (title.isEmpty || link.isEmpty) return null;
    return Article(
      title: title,
      link: link,
      source: source,
      date: _parseDate(text('pubDate')),
      imageUrl: _image(e),
    );
  }

  static String? _image(XmlElement e) {
    for (final el in e.childElements) {
      final n = el.name.qualified;
      final url = el.getAttribute('url');
      if (url == null) continue;
      if (n == 'enclosure' &&
          !(el.getAttribute('type') ?? 'image').startsWith('image')) {
        continue;
      }
      if (n == 'enclosure' || n == 'media:content' || n == 'media:thumbnail') {
        return url;
      }
    }
    final html = e.childElements
        .where((c) =>
            c.name.qualified == 'description' ||
            c.name.qualified == 'content:encoded')
        .map((c) => c.innerText)
        .join(' ');
    final m = RegExp(r'''<img[^>]+src=["']([^"']+)''').firstMatch(html);
    return m?.group(1);
  }

  static String _clean(String s) => s
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&#8217;', '’')
      .replaceAll('&nbsp;', ' ')
      .trim();

  static const _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// RFC 822 dates ("Tue, 20 Oct 2026 10:15:00 +0100"), ISO as fallback.
  static DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso.toLocal();
    final m = RegExp(
            r'(\d{1,2})\s+(\w{3})\w*\s+(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|GMT|UTC|Z)?')
        .firstMatch(s);
    if (m == null) return null;
    final month = _months[m.group(2)!.toLowerCase()];
    if (month == null) return null;
    var d = DateTime.utc(
      int.parse(m.group(3)!),
      month,
      int.parse(m.group(1)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.parse(m.group(6) ?? '0'),
    );
    final tz = m.group(7);
    if (tz != null && (tz.startsWith('+') || tz.startsWith('-'))) {
      final sign = tz.startsWith('-') ? -1 : 1;
      final off = Duration(
          hours: int.parse(tz.substring(1, 3)),
          minutes: int.parse(tz.substring(3, 5)));
      d = sign > 0 ? d.subtract(off) : d.add(off);
    }
    return d.toLocal();
  }
}
