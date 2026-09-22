import 'package:flutter/material.dart';
import 'damage_display.dart';
import 'item_image.dart';

class AmmoCard extends StatelessWidget {
  final Map<String, dynamic> ammo;

  const AmmoCard(this.ammo, {super.key});

  @override
  Widget build(BuildContext context) {
    final name = ammo['name'] as String? ?? 'Без имени';
    final icon = ammo['icon'] as String?;
    final damages = (ammo['damages'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final min = ammo['min_range']?.toString() ?? '';
    final max = ammo['max_range']?.toString() ?? '';

    return Card(
      color: const Color.fromARGB(255, 40, 40, 40),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            child: ItemImage(url: icon),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              DamageInline(damages),
              const SizedBox(height: 4),
              Text('Дальность: ${min.isNotEmpty || max.isNotEmpty ? '$min - $max' : '—'}', style: const TextStyle(color: Colors.white54)),
            ]),
          ),
        ]),
      ),
    );
  }
}