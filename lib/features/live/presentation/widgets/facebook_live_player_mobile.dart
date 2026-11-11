import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../../../core/theme/bazzar_colors.dart';

class FacebookLivePlayer extends StatefulWidget {
  final String facebookUrl;

  const FacebookLivePlayer({super.key, required this.facebookUrl});

  @override
  State<FacebookLivePlayer> createState() => _FacebookLivePlayerState();
}

class _FacebookLivePlayerState extends State<FacebookLivePlayer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isAudioActive = true;

  @override
  void initState() {
    super.initState();
    if (WebViewPlatform.instance == null) return;

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(BazzarColors.ink)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      );

    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _loadIframe();
  }

  void _loadIframe() {
    setState(() => _isLoading = true);
    _controller.loadHtmlString(
      _buildFacebookIframe(widget.facebookUrl, audioEnabled: _isAudioActive),
    );
  }

  void _toggleAudio() {
    setState(() {
      _isAudioActive = !_isAudioActive;
    });
    _loadIframe();
  }

  @override
  Widget build(BuildContext context) {
    if (WebViewPlatform.instance == null) {
      return const ColoredBox(
        color: BazzarColors.night,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'La lecture vidéo est disponible sur Android, iOS et dans le navigateur web.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: BazzarColors.ink,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BazzarColors.body, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: BazzarColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Webview Video Player
            WebViewWidget(controller: _controller),

            // 2. Loading state overlay
            if (_isLoading)
              Container(
                color: BazzarColors.ink,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: BazzarColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Connexion au flux direct...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. Top-left Badge: EN DIRECT
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF30205C), BazzarColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: BazzarColors.primary.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'EN DIRECT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Top-right Controls: Audio toggle & Reload
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Audio Toggle Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleAudio,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isAudioActive
                                ? const Color(0xFF10B981).withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isAudioActive
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              color: _isAudioActive
                                  ? const Color(0xFF10B981)
                                  : BazzarColors.muted,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isAudioActive ? 'Son ON' : 'Son OFF',
                              style: TextStyle(
                                color: _isAudioActive
                                    ? const Color(0xFF10B981)
                                    : BazzarColors.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Reload stream button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _loadIframe,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildFacebookIframe(
    String facebookUrl, {
    required bool audioEnabled,
  }) {
    final encodedUrl = Uri.encodeComponent(facebookUrl.trim());
    final muteParam = audioEnabled ? '0' : '1';

    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
* { box-sizing: border-box; }
html, body {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;
  background: #0f172a;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
}
iframe {
  width: 100%;
  height: 100%;
  border: 0;
}
</style>
</head>
<body>
<iframe
  src="https://www.facebook.com/plugins/video.php?href=$encodedUrl&autoplay=1&mute=$muteParam&show_text=false"
  allow="autoplay *; camera *; microphone *; clipboard-write *; encrypted-media *; picture-in-picture *; web-share *; fullscreen *"
  allowfullscreen="true">
</iframe>
</body>
</html>
''';
  }
}
