import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'home_gate.dart';

/// Splash screen berupa video (assets/Yukihana.mp4).
/// Video diputar sekali, lalu pindah ke halaman utama.
class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  Timer? _fallbackTimer;
  bool _started = false;
  bool _navigated = false;

  static const _backgroundColor = Color(0xFFFAF7FC);

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/Yukihana.mp4');
    _controller.addListener(_onUpdate);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _started = true);
      _controller.setVolume(0);
      _controller.play();
    }).catchError((_) {
      _goHome();
    });
    _fallbackTimer = Timer(const Duration(seconds: 12), _goHome);
  }

  void _onUpdate() {
    if (!_started || !mounted) return;
    final value = _controller.value;
    if (value.duration > Duration.zero && value.position >= value.duration) {
      _goHome();
    }
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: const HomeGate(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: _started
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
    );
  }
}
