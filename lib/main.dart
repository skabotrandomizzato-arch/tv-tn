import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'models.dart';
import 'screens/favorites_screen.dart';
import 'screens/news_screen.dart';
import 'screens/radio_screen.dart';
import 'screens/tv_screen.dart';
import 'services/catalog_service.dart';
import 'services/favorites.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.skander.tunisia_tv.audio',
      androidNotificationChannelName: 'Tounsi Live',
      androidNotificationOngoing: true,
    ).timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('Audio init fallito: $e');
  }
  runApp(const TounsiApp());
}

class TounsiApp extends StatelessWidget {
  const TounsiApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFC8102E);
    return MaterialApp(
      title: 'Tounsi Live',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      ),
      home: const HomeShell(),
    );
  }
}

/// Loads the catalog and favorites, then shows the four tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late Future<Catalog> _future = _load();
  int _index = 0;

  Future<Catalog> _load() async {
    await Favorites.instance.init();
    return CatalogService.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Catalog>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text('Erreur de chargement\n${snap.error}',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final catalog = snap.data!;
        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              TvScreen(channels: catalog.tv),
              RadioScreen(stations: catalog.radio),
              NewsScreen(sources: catalog.news),
              FavoritesScreen(catalog: catalog),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniRadioBar(),
              NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.live_tv_outlined),
                      selectedIcon: Icon(Icons.live_tv),
                      label: 'TV'),
                  NavigationDestination(
                      icon: Icon(Icons.radio_outlined),
                      selectedIcon: Icon(Icons.radio),
                      label: 'Radio'),
                  NavigationDestination(
                      icon: Icon(Icons.article_outlined),
                      selectedIcon: Icon(Icons.article),
                      label: 'Actualités'),
                  NavigationDestination(
                      icon: Icon(Icons.star_outline),
                      selectedIcon: Icon(Icons.star),
                      label: 'Favoris'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
