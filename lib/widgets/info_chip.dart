import 'package:flutter/material.dart';

class InfoChip extends StatelessWidget {
  final String label;
  const InfoChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          softWrap: true,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ),
    );
  }
}