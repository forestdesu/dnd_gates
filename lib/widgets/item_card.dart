import 'package:flutter/material.dart';
import '../screens/community.dart' show Item, MyItem, statusColors, statusLabels;
import '../utils/price_formatter.dart';
import 'item_image.dart';
import 'info_chip.dart';

const rarityColors = <String, Color>{
  'Обычный': Color(0xFFADB5BD),
  'Необычный': Color(0xFF4CD964),
  'Редкий': Color(0xFF4DA3FF),
  'Очень редкий': Color(0xFFEFE478),
  'Легендарный': Color(0xFFFF5A55),
  'Артефакт': Color(0xFFFF9900),
  'Не имеет редкости': Color(0xFF7A8188),
};

const varyingRarityGradient = <Color>[
  Color(0xFFADB5BD), Color(0xFF4CD964), Color(0xFF4DA3FF),
  Color(0xFFEFE478), Color(0xFFFF5A55), Color(0xFFFF9900),
];

class ItemNameText extends StatelessWidget {
  final String name;
  final String rarity;
  final TextStyle? baseStyle;

  const ItemNameText(this.name, this.rarity, {super.key, this.baseStyle});

  @override
  Widget build(BuildContext context) {
    if (rarity == 'Редкость варьируется') {
      return ShaderMask(
        shaderCallback: (b) => const LinearGradient(colors: varyingRarityGradient).createShader(b),
        child: Text(name, style: baseStyle?.copyWith(color: Colors.white)),
      );
    }
    return Text(name, style: baseStyle?.copyWith(color: rarityColors[rarity] ?? Colors.white));
  }
}

class PublicItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;

  const PublicItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onTap,
        child: Card(
          color: const Color.fromARGB(255, 40, 40, 40),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 100,
                  height: 200,
                  child: ItemImage(url: item.icon, fit: BoxFit.fill),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    ItemNameText(item.name, item.rarity, baseStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Тип: ${item.types.isNotEmpty ? item.types.join(", ") : "Не определен"}', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 6),
                    Text('Стоимость: ${item.price.asPrice}', style: theme.textTheme.labelSmall?.copyWith(color: Colors.amber)),
                    if (item.specialTypes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(spacing: 3, runSpacing: 2, children: item.specialTypes.map((s) => InfoChip(s)).toList()),
                    ],
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class MyItemCard extends StatelessWidget {
  final MyItem item;
  final VoidCallback onTap;

  const MyItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = statusColors[item.status] ?? Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onTap,
        child: Card(
          color: const Color.fromARGB(255, 40, 40, 40),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              SizedBox(width: 60, height: 60, child: ItemImage(url: item.icon, fit: BoxFit.fill)),
                const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.name, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Редкость: ${item.rarity}', style: theme.textTheme.labelSmall),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Text(statusLabels[item.status] ?? '—', style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}