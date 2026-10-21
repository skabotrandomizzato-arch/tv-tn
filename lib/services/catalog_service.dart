import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// Where the app looks for an updated channel list. Host a copy of
/// assets/catalog.json (GitHub raw, Gist, Firebase Hosting...) and put its
/// URL here: stream links break often, and this lets you fix them without
/// publishing a new version. Leave empty to only use the bundled list.
const remoteCatalogUrl = '';

class CatalogService {
  static const _cacheKey = 'catalog_cache';

  /// Returns the cached remote catalog if any, else the bundled one.
  /// Then refreshes the cache in the background for next launch.
  static Future<Catalog> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    Catalog? catalog;
    if (cached != null) {
      try {
        catalog = Catalog.fromJson(jsonDecode(cached));
      } catch (_) {}
    }
    catalog ??= Catalog.fromJson(
        jsonDecode(await rootBundle.loadString('assets/catalog.json')));
    _refresh(prefs);
    return catalog;
  }

  static Future<void> _refresh(SharedPreferences prefs) async {
    if (remoteCatalogUrl.isEmpty) return;
    try {
      final res = await http
          .get(Uri.parse(remoteCatalogUrl))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final body = utf8.decode(res.bodyBytes);
      Catalog.fromJson(jsonDecode(body)); // validate before caching
      await prefs.setString(_cacheKey, body);
    } catch (_) {}
  }
}
