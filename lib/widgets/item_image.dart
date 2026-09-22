import 'package:flutter/material.dart';

class ItemImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;

  const ItemImage({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Image.asset('assets/no-picture.png', fit: fit);
    }
    return Image.network(
      url!,
      fit: fit,
      errorBuilder: (c, e, st) => Image.asset('assets/no-picture.png', fit: fit),
    );
  }
}