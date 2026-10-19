import 'package:flutter/material.dart';
import 'package:safe_yt_flutter/api.dart';
import 'package:safe_yt_flutter/video.dart';

class VideoList extends StatelessWidget {
  const VideoList({
    super.key,
    required this._videos,
    required this._loadMore,
  });

  final List<VideoItem> _videos;

  final dynamic _loadMore;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. The Video Grid
          Padding(
            padding: const EdgeInsets.all(10.0), // Give it some breathing room
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _videos.map((video) => VideoEntry(video: video)).toList(),
            ),
          ),
    
          // 2. The Load More button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton.filled(
                onPressed: _loadMore,
                icon: const Icon(Icons.expand_more),
                tooltip: "Load more",
                iconSize: 50,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
