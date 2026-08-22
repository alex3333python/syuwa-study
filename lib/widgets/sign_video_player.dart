import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SignVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const SignVideoPlayer({super.key, required this.videoUrl});

  @override
  State<SignVideoPlayer> createState() => _SignVideoPlayerState();
}

class _SignVideoPlayerState extends State<SignVideoPlayer> {
  VideoPlayerController? _controller;
  bool isInitialized = false;
  String? errorMessage;
  int _setupGeneration = 0;

  bool get isNetworkVideo =>
      widget.videoUrl.startsWith('http://') ||
      widget.videoUrl.startsWith('https://');

  @override
  void initState() {
    super.initState();
    setupVideo();
  }

  Future<void> setupVideo() async {
    final generation = ++_setupGeneration;
    VideoPlayerController? controller;

    try {
      controller = isNetworkVideo
          ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          : VideoPlayerController.asset(widget.videoUrl);
      _controller = controller;

      await controller.initialize();
      if (!mounted || generation != _setupGeneration) {
        await controller.dispose();
        if (identical(_controller, controller)) {
          _controller = null;
        }
        return;
      }

      await controller.setLooping(true);
      // Muted autoplay is allowed on Safari; keep volume at 0.
      await controller.setVolume(0.0);
      await controller.play();

      controller.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

      if (mounted && generation == _setupGeneration) {
        setState(() {
          isInitialized = true;
          errorMessage = null;
        });
      }
    } catch (e) {
      await controller?.dispose();
      if (identical(_controller, controller)) {
        _controller = null;
      }
      if (mounted && generation == _setupGeneration) {
        setState(() {
          isInitialized = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _setupGeneration++;
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  Future<void> togglePlay() async {
    final controller = _controller;
    if (!isInitialized || controller == null) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '動画を読み込めません\n$errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final controller = _controller;
    if (!isInitialized || controller == null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: togglePlay,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
              if (!controller.value.isPlaying)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
