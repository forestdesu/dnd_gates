import 'package:flutter/material.dart';
import 'package:dotlottie_flutter/dotlottie_flutter.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;

  const LoadingIndicator({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const DotLottieView(
        sourceType: 'asset',
        source: 'loading.lottie',
        autoplay: true,
        loop: true,
      ),
    );
  }
}