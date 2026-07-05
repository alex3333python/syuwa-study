import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SignVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const SignVideoPlayer({super.key, required this.videoUrl});

  @override
  State<SignVideoPlayer> createState() => _SignVideoPlayerState();
}

class _SignVideoPlayerState extends State<SignVideoPlayer> {
  late VideoPlayerController _controller;
  bool isInitialized = false;
  String? errorMessage;

  bool get isNetworkVideo =>
      widget.videoUrl.startsWith('http://') ||
      widget.videoUrl.startsWith('https://');

  @override
  void initState() {
    super.initState();
    setupVideo();
  }

  Future<void> setupVideo() async {
    try {
      _controller = isNetworkVideo
          ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          : VideoPlayerController.asset(widget.videoUrl);

      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0.0);
      await _controller.play();

      _controller.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    if (isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> togglePlay() async {
    if (!isInitialized) return;

    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }

    setState(() {});
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

    if (!isInitialized) {
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
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              if (!_controller.value.isPlaying)
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
