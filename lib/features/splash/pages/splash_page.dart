import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/core/constants/app_assets.dart';
import 'package:video_player/video_player.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final VideoPlayerController _controller;
  Timer? _fallbackTimer;
  bool _isReady = false;
  bool _didFinish = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(AppAssets.splashVideo)
      ..addListener(_handleVideoState);
    unawaited(_initializeVideo());
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize().timeout(const Duration(seconds: 10));
      await _controller.setVolume(0);
      await _controller.setLooping(false);

      if (!mounted) {
        return;
      }

      setState(() => _isReady = true);
      _fallbackTimer = Timer(
        _controller.value.duration + const Duration(seconds: 2),
        _finish,
      );
      await _controller.play();
    } on Object {
      _finish();
    }
  }

  void _handleVideoState() {
    final value = _controller.value;
    if (value.hasError ||
        (value.isInitialized &&
            value.duration > Duration.zero &&
            value.position >= value.duration)) {
      _finish();
    }
  }

  void _finish() {
    if (_didFinish || !mounted) {
      return;
    }
    _didFinish = true;
    _fallbackTimer?.cancel();
    widget.onFinished();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller
      ..removeListener(_handleVideoState)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: !_isReady
          ? const SizedBox.expand()
          : SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
    );
  }
}
