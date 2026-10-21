import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Favorites extends ChangeNotifier {
  Favorites._();
  static final instance = Favorites._();

  static const _key = 'favorites';
  final Set<String> _keys = {};
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _keys.addAll(_prefs!.getStringList(_key) ?? const []);
  }

  bool contains(String key) => _keys.contains(key);

  void toggle(String key) {
    if (!_keys.remove(key)) _keys.add(key);
    _prefs?.setStringList(_key, _keys.toList());
    notifyListeners();
  }
}
