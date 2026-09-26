import 'package:flutter/material.dart';
import '../screens/community.dart' show Item, MyItem, statusColors;
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
  Color(0xFFADB5BD),
];

class RarityShimmerText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  const RarityShimmerText(this.text, {super.key, this.style});

  @override
  State<RarityShimmerText> createState() => _RarityShimmerTextState();
}

class _RarityShimmerTextState extends State<RarityShimmerText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final Animation<double> _curved = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) {
        final shift = _curved.value * 2;
        return ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: varyingRarityGradient,
            tileMode: TileMode.repeated,
            begin: Alignment(-1 - shift, 0),
            end: Alignment(1 - shift, 0),
          ).createShader(b),
          child: Text(widget.text, style: widget.style?.copyWith(color: Colors.white)),
        );
      },
    );
  }
}

class ItemNameText extends StatelessWidget {
  final String name;
  final String rarity;
  final TextStyle? baseStyle;

  const ItemNameText(this.name, this.rarity, {super.key, this.baseStyle});

  @override
  Widget build(BuildContext context) {
    if (rarity == 'Редкость варьируется') {
      return RarityShimmerText(name, style: baseStyle);
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
          child: SizedBox(
            height: 210,
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(
                width:  140,
                height: double.infinity,
                child: ClipRRect(borderRadius: BorderRadius.circular(12), child: ItemImage(url: item.icon, fit: BoxFit.fill)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    ItemNameText(item.name, item.rarity, baseStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Тип: ${item.types.isNotEmpty ? item.types.join(", ") : "Не определен"}', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 6),
                    Text('${item.price.asPrice}', style: theme.textTheme.labelSmall?.copyWith(color: Colors.amber)),
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
          child: SizedBox(
            height: 100, // ИЗМЕНЕНО: 125 -> 150, чтобы хватало места на 2 строки текста + бейдж
            child: Row(children: [
              SizedBox(
                  width: 100,
                  height: double.infinity,
                  child: ClipRRect(borderRadius: BorderRadius.circular(12), child: ItemImage(url: item.icon, fit: BoxFit.fill))),
              Expanded( // НОВОЕ: правая часть теперь тянется на всю оставшуюся ширину, текст не может распереть карточку
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            Flexible(
                              child: Text(item.name, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item.rarity, style: theme.textTheme.labelSmall),
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