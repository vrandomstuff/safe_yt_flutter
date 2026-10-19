import 'package:flutter/foundation.dart';
import 'package:safe_yt_flutter/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VideoItem {
  final String id;
  final String thumbnail;
  final String channel;
  final String channelAvatar;
  final String channelName;
  final String title;

  VideoItem({
    required this.id,
    required this.thumbnail,
    required this.channel,
    required this.channelAvatar,
    required this.channelName,
    required this.title
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      id: json['id'] as String,
      thumbnail: json['thumbnail'] as String,
      channel: json['channel'] as String,
      channelAvatar: json['channelAvatar'] as String,
      channelName: json['channelName'] as String,
      title: json['title'] as String
    );
  }
}


class Api {
    final Config _config = Config();
    Future<String?> get apiBaseUrl async => await _config.getApiUrl();

    List<VideoItem> parseVideoList(String jsonString) {
      final List<dynamic> parsedList = jsonDecode(jsonString);

      final List<VideoItem> videos = parsedList.map((item) {
        return VideoItem.fromJson(item as Map<String, dynamic>);
      }).toList();

      return videos;
    }
    Future<List<VideoItem>?> getVideos(int page, [String route = "videos"]) async {
        if (await apiBaseUrl == null) {
          return null;
        }
        var response = await http.get(Uri.parse("${await apiBaseUrl}/$route?page=${page.toString()}"));
        if(response.statusCode != 200) {
            debugPrint("getVideos: HTTP failed: ${response.statusCode} ${response.reasonPhrase}");
            return null;
        }
        return parseVideoList(response.body);
    }

    Future<http.Response> postWatch(String id) async {
        return await http.post(Uri.parse("${await apiBaseUrl}/watch/$id"));
    }

}
