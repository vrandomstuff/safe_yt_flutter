import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:safe_yt_flutter/config.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({required this.videoId, super.key});

  final String? videoId;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final Config _config = Config();
  Future<String?> get apiBaseUrl async => await _config.getApiUrl();
  Player? _player;
  VideoController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    final apiUrl = await apiBaseUrl;
    if (apiUrl != null && widget.videoId != null) {
      final videoUrl = '$apiUrl/m3u8/${widget.videoId}';
      final player = Player();
      final controller = VideoController(player);
      if (!mounted) {
        await player.dispose();
        return;
      }
      setState(() {
        _player = player;
        _controller = controller;
      });
      await player.open(Media(videoUrl));
    } else {
      throw FlutterError('API URL or Video ID is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(),
      body: controller != null
          ? Video(controller: controller)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }
}
