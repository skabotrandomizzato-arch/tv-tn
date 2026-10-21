import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../models.dart';
import '../services/radio_player.dart';
import '../widgets/common.dart';

class PlayerScreen extends StatefulWidget {
  final TvChannel channel;
  final List<TvChannel> channels;
  const PlayerScreen({super.key, required this.channel, required this.channels});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late TvChannel _channel = widget.channel;

  @override
  void initState() {
    super.initState();
    RadioPlayer.instance.pause();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _setFullscreen(bool on) {
    if (on) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // Let the user rotate freely again once back in portrait.
      Future.delayed(const Duration(seconds: 2),
          () => SystemChrome.setPreferredOrientations([]));
    }
  }

  Future<void> _openYoutube() async {
    final id = _channel.youtubeChannelId;
    if (id == null) return;
    await launchUrl(Uri.parse('https://www.youtube.com/channel/$id/live'),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final player = ChannelPlayer(
      key: ValueKey(_channel.id),
      channel: _channel,
      fullscreen: landscape,
      onFullscreen: () => _setFullscreen(!landscape),
    );

    if (landscape) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) => _setFullscreen(false),
        child: Scaffold(backgroundColor: Colors.black, body: Center(child: player)),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final others = widget.channels.where((c) => c.id != _channel.id).toList();
    return Scaffold(
      appBar: AppBar(title: Text(_channel.name)),
      body: Column(
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: player),
          ListTile(
            leading: ChannelBadge(name: _channel.name, color: _channel.color),
            title: Text(_channel.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Row(children: [
              const LiveDot(),
              const SizedBox(width: 6),
              Text(_channel.category),
            ]),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_channel.youtubeChannelId != null)
                  IconButton(
                    tooltip: 'Ouvrir dans YouTube',
                    icon: const Icon(Icons.open_in_new_rounded),
                    onPressed: _openYoutube,
                  ),
                FavoriteButton(favKey: _channel.favKey),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Autres chaînes',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: others.length,
              itemBuilder: (context, i) {
                final c = others[i];
                return ListTile(
                  leading: ChannelBadge(name: c.name, color: c.color, size: 40),
                  title: Text(c.name),
                  subtitle: Text(c.category),
                  onTap: () => setState(() => _channel = c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Plays a channel: direct HLS when available, otherwise (or when HLS fails)
/// the official YouTube live stream.
class ChannelPlayer extends StatefulWidget {
  final TvChannel channel;
  final bool fullscreen;
  final VoidCallback onFullscreen;

  const ChannelPlayer({
    super.key,
    required this.channel,
    required this.fullscreen,
    required this.onFullscreen,
  });

  @override
  State<ChannelPlayer> createState() => _ChannelPlayerState();
}

class _ChannelPlayerState extends State<ChannelPlayer> {
  VideoPlayerController? _video;
  WebViewController? _web;
  bool _error = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  void _start() {
    final c = widget.channel;
    if (c.type == StreamType.hls && c.url != null) {
      _startHls(c.url!);
    } else if (c.youtubeChannelId != null) {
      _startYoutube(c.youtubeChannelId!);
    } else {
      setState(() => _error = true);
    }
  }

  Future<void> _startHls(String url) async {
    final v = VideoPlayerController.networkUrl(Uri.parse(url),
        formatHint: VideoFormat.hls);
    _video = v;
    v.addListener(_onVideo);
    try {
      await v.initialize();
      await v.play();
      _hideControlsSoon();
    } catch (_) {
      _fallback();
    }
    if (mounted) setState(() {});
  }

  void _onVideo() {
    if (_video?.value.hasError ?? false) _fallback();
    if (mounted) setState(() {});
  }

  void _fallback() {
    final yt = widget.channel.youtubeChannelId;
    _video?.removeListener(_onVideo);
    _video?.dispose();
    _video = null;
    if (yt != null && _web == null) {
      _startYoutube(yt);
    } else {
      _error = true;
    }
    if (mounted) setState(() {});
  }

  void _startYoutube(String channelId) {
    final web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);
    final platform = web.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }
    // YouTube requires an embedding origin (otherwise "error 153"),
    // so the iframe is loaded from an HTML page with a base URL.
    web.loadHtmlString('''
<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<style>html,body{margin:0;height:100%;background:#000;overflow:hidden}
iframe{position:absolute;inset:0;width:100%;height:100%;border:0}</style>
</head><body>
<iframe src="https://www.youtube.com/embed/live_stream?channel=$channelId&autoplay=1&playsinline=1&rel=0&modestbranding=1"
 allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
 referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
</body></html>''', baseUrl: 'https://tounsilive.app');
    _web = web;
  }

  void _retry() {
    setState(() {
      _error = false;
      _web = null;
    });
    _start();
  }

  void _hideControlsSoon() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && (_video?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_error) {
      content = _ErrorView(onRetry: _retry);
    } else if (_web != null) {
      content = Stack(children: [
        WebViewWidget(controller: _web!),
        Positioned(
          right: 4,
          bottom: 44,
          child: _RoundButton(
            icon: widget.fullscreen
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            onTap: widget.onFullscreen,
          ),
        ),
      ]);
    } else if (_video?.value.isInitialized ?? false) {
      final v = _video!;
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _showControls = !_showControls);
          if (_showControls) _hideControlsSoon();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio:
                    v.value.aspectRatio > 0 ? v.value.aspectRatio : 16 / 9,
                child: VideoPlayer(v),
              ),
            ),
            if (v.value.isBuffering)
              const CircularProgressIndicator(color: Colors.white),
            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  color: Colors.black38,
                  child: Stack(children: [
                    Center(
                      child: _RoundButton(
                        size: 64,
                        icon: v.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        onTap: () {
                          v.value.isPlaying ? v.pause() : v.play();
                          setState(() {});
                        },
                      ),
                    ),
                    const Positioned(left: 12, top: 12, child: LiveDot()),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: _RoundButton(
                        icon: widget.fullscreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        onTap: widget.onFullscreen,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      content = const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return ColoredBox(color: Colors.black, child: content);
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _RoundButton({required this.icon, required this.onTap, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.6),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.signal_wifi_bad_rounded,
              color: Colors.white70, size: 40),
          const SizedBox(height: 8),
          const Text('Diffusion indisponible pour le moment',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
