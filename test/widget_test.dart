import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tunisia_tv/models.dart';

void main() {
  test('bundled catalog parses', () {
    final json = jsonDecode(File('assets/catalog.json').readAsStringSync());
    final c = Catalog.fromJson(json);
    expect(c.tv, isNotEmpty);
    expect(c.radio, isNotEmpty);
    expect(c.news, isNotEmpty);
    for (final ch in c.tv) {
      expect(ch.url != null || ch.youtubeChannelId != null, isTrue,
          reason: ch.name);
    }
  });
}
