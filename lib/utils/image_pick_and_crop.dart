import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/crop_screen.dart';

const _kMinSide = 300;

Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<File?> pickAndCropImage(BuildContext context) async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  final image = await _decode(bytes);
  if (image.width < _kMinSide || image.height < _kMinSide) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Минимальный размер изображения ${_kMinSide}x$_kMinSide px (сейчас ${image.width}x${image.height})')),
    );
    return null;
  }
  if (!context.mounted) return null;

  final cropped = await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => CropScreen(imageBytes: bytes)),
  );
  if (cropped == null) return null;

  final file = File('${Directory.systemTemp.path}/${DateTime.now().microsecondsSinceEpoch}.png');
  return file.writeAsBytes(cropped);
}