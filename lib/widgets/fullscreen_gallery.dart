import 'package:flutter/material.dart';

class FullscreenGallery extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const FullscreenGallery({super.key, required this.urls, required this.initialIndex});

  @override
  State<FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<FullscreenGallery> {
  late final _controller = PageController(initialPage: widget.initialIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.urls.length,
        itemBuilder: (context, i) => Center(
          child: Hero(
            tag: 'item_image_${widget.urls[i]}',
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.network(widget.urls[i], fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}