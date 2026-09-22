import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

const _kMinCropSide = 300;

class CropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const CropScreen({super.key, required this.imageBytes});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  CropController _controller = CropController();
  bool _cropping = false;
  Key _cropKey = UniqueKey();

  Future<void> _validateAndReturn(Uint8List croppedImage) async {
    final codec = await ui.instantiateImageCodec(croppedImage);
    final frame = await codec.getNextFrame();
    if (frame.image.width < _kMinCropSide || frame.image.height < _kMinCropSide) {
      if (!mounted) return;
      setState(() => _cropping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Результат обрезки меньше ${_kMinCropSide}x$_kMinCropSide px — увеличьте область выделения')),
      );
      return;
    }
    if (mounted) Navigator.of(context).pop(croppedImage);
  }

  void _resetCrop() {
    setState(() {
      _controller = CropController();
      _cropKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 31, 31, 31),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена', style: TextStyle(color: Colors.white70)),
        ),
        title: const Text('Обрезка изображения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Сбросить рамку',
            onPressed: _resetCrop,
          ),
          TextButton(
            onPressed: _cropping ? null : () {
              setState(() => _cropping = true);
              _controller.crop();
            },
            child: const Text('Готово', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Crop(
        key: _cropKey,
        controller: _controller,
        image: widget.imageBytes,
        baseColor: const Color.fromARGB(255, 31, 31, 31),
        maskColor: Colors.black.withValues(alpha: 0.6),
        onCropped: (result) {
          switch (result) {
            case CropSuccess(:final croppedImage):
              _validateAndReturn(croppedImage);
            case CropFailure(:final cause):
              setState(() => _cropping = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка обрезки: $cause')),
              );
          }
        },
      ),
    );
  }
}