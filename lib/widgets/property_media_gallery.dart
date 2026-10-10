import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/property_media.dart';

class PropertyMediaGallery extends StatelessWidget {
  const PropertyMediaGallery({
    required this.media,
    required this.height,
    super.key,
  });

  final List<PropertyMedia> media;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: PageView.builder(
          itemCount: media.length,
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: media[index].type == 'video'
                ? _VideoPreview(media: media[index])
                : Image.network(
                    media[index].url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const _MediaError(),
                  ),
          ),
        ),
      );
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({required this.media});

  final PropertyMedia media;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.media.url));
    _initialization = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const _MediaError();
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                }),
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
              ),
            ],
          );
        },
      );
}

class _MediaError extends StatelessWidget {
  const _MediaError();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFFE5ECE7),
        child: Center(
          child: Icon(Icons.broken_image_outlined, size: 44),
        ),
      );
}
