import 'package:flutter/material.dart';

class InfoChip extends StatelessWidget {
  final String label;
  const InfoChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          softWrap: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}