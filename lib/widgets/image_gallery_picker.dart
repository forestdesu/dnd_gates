import 'dart:io';
import 'package:flutter/material.dart';

class GalleryImage {
  final int? id;
  final String? url;
  final File? localFile;
  bool uploading;
  bool deleting;

  GalleryImage.server({required this.id, required this.url, this.uploading = false, this.deleting = false}) : localFile = null;
  GalleryImage.local(File file, {this.uploading = false, this.deleting = false}) : localFile = file, id = null, url = null;

  String get _key => id?.toString() ?? localFile!.path;
}

class ImageGalleryPicker extends StatelessWidget {
  final List<GalleryImage> images;
  final VoidCallback onAdd;
  final ValueChanged<GalleryImage> onRemove;
  final ValueChanged<List<GalleryImage>> onReorder;
  final int maxImages;

  const ImageGalleryPicker({
    super.key,
    required this.images,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
    this.maxImages = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ReorderableListView(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex -= 1;
          final updated = [...images];
          final item = updated.removeAt(oldIndex);
          updated.insert(newIndex, item);
          onReorder(updated);
        },
        children: [
          for (var i = 0; i < images.length; i++)
            images[i].uploading || images[i].deleting
                ? Padding(
              key: ValueKey(images[i]._key),
              padding: const EdgeInsets.only(right: 8),
              child: _Thumb(image: images[i], onDelete: () {}),
            )
                : ReorderableDragStartListener(
              key: ValueKey(images[i]._key),
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Thumb(image: images[i], onDelete: () => onRemove(images[i])),
              ),
            ),
          if (images.length < maxImages)
            Padding(
              key: const ValueKey('add_slot'),
              padding: const EdgeInsets.only(right: 8),
              child: _AddSlot(onTap: onAdd),
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final GalleryImage image;
  final VoidCallback onDelete;

  const _Thumb({required this.image, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[900]),
        clipBehavior: Clip.antiAlias,
        child: image.localFile != null
            ? Image.file(image.localFile!, fit: BoxFit.cover)
            : Image.network(image.url!, fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.broken_image, color: Colors.grey)),
      ),
      if (image.uploading || image.deleting)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black54),
            child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
          ),
        )
      else
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
    ]);
  }
}

class _AddSlot extends StatelessWidget {
  final VoidCallback onTap;
  const _AddSlot({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
        child: const Icon(Icons.add_a_photo, color: Colors.white38),
      ),
    );
  }
}