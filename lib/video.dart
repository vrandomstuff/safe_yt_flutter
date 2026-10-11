import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:safe_yt_flutter/api.dart';

class VideoEntry extends StatelessWidget {
  const VideoEntry({required this._video, super.key});

  final VideoItem _video;
  
   @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15), // Replaces borderRadius
              child: Semantics(
                label: 'Thumbnail for the video: ${_video.title}', // Replaces alt
                image: true,
                 child: CachedNetworkImage(
                   imageUrl: _video.thumbnail,
                   width: 420,             // Fixed width
                   height: 236,            // Fixed height
                   fit: BoxFit.cover,      // Ensures it fills the box like an img tag
                   fadeInDuration: Duration.zero,
                   fadeOutDuration: Duration.zero,
                   errorWidget: (context, url, error) => Container(
                     width: 420,
                     height: 236,
                     color: Colors.grey[800],
                   ),
                 ),
              ),
            ),
             SizedBox(
               width: 420,
               child: Text(
                 _video.title,
                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                 maxLines: 2,
                 overflow: TextOverflow.ellipsis,
               ),
             ),
          Row(
            children: [
              Tooltip(
                message:_video.channelName,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50), // Circular border radius
                  child: Container(
                    width: 50,
                    height: 50,
                    color: Colors.transparent, // Background color
                    child: Semantics(
                      label: _video.channelName, // Alternative text
                      image: true,
                       child: CachedNetworkImage(
                         imageUrl: _video.channelAvatar,
                         fit: BoxFit.cover,
                         fadeInDuration: Duration.zero,
                         fadeOutDuration: Duration.zero,
                         errorWidget: (context, url, error) => Container(
                           width: 50,
                           height: 50,
                           color: Colors.grey[800],
                         ),
                       ),
                    ),
                  ),
                ),
              ),
              Text(_video.channelName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),)
            ],
           )
          ],
        ),
      ],
    ),
  );
  }
}