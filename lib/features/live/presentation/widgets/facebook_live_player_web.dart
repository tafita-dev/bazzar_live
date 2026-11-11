import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../../core/theme/bazzar_colors.dart';

/// Browser video embed. No native WebView controller is created on the web.
class FacebookLivePlayer extends StatefulWidget {
  const FacebookLivePlayer({super.key, required this.facebookUrl});
  final String facebookUrl;

  @override
  State<FacebookLivePlayer> createState() => _FacebookLivePlayerState();
}

class _FacebookLivePlayerState extends State<FacebookLivePlayer> {
  bool _audioEnabled = true;
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final source = Uri.https('www.facebook.com', '/plugins/video.php', {
      'href': widget.facebookUrl.trim(),
      'autoplay': '1',
      'mute': _audioEnabled ? '0' : '1',
      'show_text': 'false',
    }).toString();

    return ColoredBox(
      color: BazzarColors.night,
      child: Column(
        children: [
          // Keep Flutter controls outside the iframe so it cannot intercept taps.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Vidéo de la boutique',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _audioEnabled ? 'Couper le son' : 'Activer le son',
                  onPressed: () =>
                      setState(() => _audioEnabled = !_audioEnabled),
                  icon: Icon(
                    _audioEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  tooltip: 'Recharger la vidéo',
                  onPressed: () => setState(() => _reload++),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: HtmlElementView.fromTagName(
              key: ValueKey('$source:$_reload'),
              tagName: 'iframe',
              onElementCreated: (element) {
                final frame = element as web.HTMLIFrameElement;
                frame
                  ..title = 'Vidéo Facebook de la boutique'
                  ..src = source
                  ..allow =
                      'autoplay; encrypted-media; picture-in-picture; fullscreen'
                  ..allowFullscreen = true;
                frame.style
                  ..width = '100%'
                  ..height = '100%'
                  ..border = '0';
              },
            ),
          ),
        ],
      ),
    );
  }
}
