import 'package:flutter/material.dart';
import 'dart:convert';
import 'services/api_service.dart';
import 'widgets/loading_indicator.dart';
import 'widgets/info_chip.dart';

class ItemDetailPage extends StatefulWidget {
  final int itemId;
  final String? initialName;
  final String? initialImageUrl;

  const ItemDetailPage({super.key, required this.itemId, this.initialName, this.initialImageUrl});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;
  bool _ammoExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  static const Map<String, ({String icon, Color color})> _damageTypeInfo = {
    'Дробящий': (icon: 'assets/Bludgeoning_Damage_Icon.webp', color: Color(0xFFD9D9D9)),
    'Колющий': (icon: 'assets/Piercing_Damage_Icon.webp', color: Color(0xFFD9D9D9)),
    'Рубящий': (icon: 'assets/Slashing_Damage_Icon.webp', color: Color(0xFFD9D9D9)),
    'Кислотный': (icon: 'assets/Acid_Damage_Icon.webp', color: Color(0xFF73E600)),
    'Холод': (icon: 'assets/Cold_Damage_Icon.webp', color: Color(0xFF00AEEF)),
    'Огонь': (icon: 'assets/Fire_Damage_Icon.webp', color: Color(0xFFFF8C00)),
    'Силовой': (icon: 'assets/Force_Damage_Icon.webp', color: Color(0xFFE65B5B)),
    'Электрический': (icon: 'assets/Lightning_Damage_Icon.webp', color: Color(0xFF69B7D9)),
    'Некротический': (icon: 'assets/Necrotic_Damage_Icon.webp', color: Color(0xFF58B77D)),
    'Ядовитый': (icon: 'assets/Poison_Damage_Icon.webp', color: Color(0xFF72A82E)),
    'Психический': (icon: 'assets/Psychic_Damage_Icon.webp', color: Color(0xFFD65CCF)),
    'Излучающий': (icon: 'assets/Radiant_Damage_Icon.webp', color: Color(0xFFE8D96A)),
    'Звуковой': (icon: 'assets/Thunder_Damage_Icon.webp', color: Color(0xFF9466CC)),
  };

  Widget _damagePiece(String? damage, String? damageType) {
    final info = _damageTypeInfo[damageType];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (info != null) ...[
          Image.asset(info.icon, width: 18, height: 18),
          const SizedBox(width: 6),
        ],
        Text(
          damage ?? '—',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: info?.color ?? Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _damageInline(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final sorted = [...rows]..sort((a, b) {
      final so = (a['sort_order'] as int? ?? 0).compareTo(b['sort_order'] as int? ?? 0);
      if (so != 0) return so;
      return (a['damage_type'] as String? ?? '').compareTo(b['damage_type'] as String? ?? '');
    });

    final children = <Widget>[];
    int? prevSortOrder;
    for (final r in sorted) {
      final so = r['sort_order'] as int?;
      if (prevSortOrder != null) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            so == prevSortOrder ? '/' : '+',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ));
      }
      children.add(_damagePiece(r['damage'] as String?, r['damage_type'] as String?));
      prevSortOrder = so;
    }

    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: children);
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await ApiService.getItem(widget.itemId.toString());
      if (response.statusCode == 200) {
        data = jsonDecode(response.body) as Map<String, dynamic>?;
      } else {
        error = 'Ошибка сервера: ${response.statusCode}';
      }
    } catch (e) {
      error = 'Ошибка подключения: $e';
    }

    setState(() {
      loading = false;
    });
  }

  String _formatPrice(int price) {
    // Цены приходят в медных. Курс: 100 медных = 10 серебрянных = 1 золотой.
    // Показываем максимально крупную целую валюту: зол., сер., или мед.
    if (price <= 0) return 'Бесплатно';
    if (price % 100 == 0) {
      final g = price ~/ 100;
      return '$g зол.';
    } else if (price % 10 == 0) {
      final s = price ~/ 10;
      return '$s серебр.';
    } else {
      return '$price мед.';
    }
  }

  Widget _maybeSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  // Helper: label on the left, value aligned to the right
  Widget _keyValueRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(children: [
        Text('$label', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(width: 8),
        Expanded(
          child: Align(alignment: Alignment.centerRight, child: value),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialName ?? 'Предмет'),
        backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
      ),
      body: loading
          ? const Center(child: LoadingIndicator())
          : (error != null
              ? Center(child: Text(error!, style: theme.textTheme.bodyMedium))
              : _buildContent(context)),
    );
  }

  Widget _buildContent(BuildContext context) {
    final Map<String, dynamic> d = data ?? {};
    final name = d['name'] as String? ?? widget.initialName ?? 'Без названия';
    final icon = d['icon'] as String? ?? widget.initialImageUrl;
    final price = d['price'] as int? ?? 0;
    final description = d['description'] as String? ?? '';
    final rarity = d['rarity'] as String?;
    final weight = d['weight']?.toString();
    final specialTypes = (d['special_types'] as List<dynamic>?)?.map((e) => e['name'] as String? ?? '').where((s) => s.isNotEmpty).toList() ?? [];
    // types not used directly in UI for now
    final weaponClasses = (d['weapon_classes'] as List<dynamic>?)?.map((e) => e['name'] as String? ?? '').where((s) => s.isNotEmpty).toList() ?? [];
    final weaponTypes = (d['weapon_types'] as List<dynamic>?)?.map((e) => e['name'] as String? ?? '').where((s) => s.isNotEmpty).toList() ?? [];
    final hands = (d['hands'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final ranges = (d['ranges'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final ammos = (d['ammos'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final compatibleAmmos = (d['compatible_ammos'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Название
        Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 12),
        // Картинка: высота = ширина экрана, ширина чуть меньше чтобы не терялись пропорции; изображение выровнено по центру и использует BoxFit.fill
        Builder(builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final imageHeight = screenWidth; // высота равна ширине экрана
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: SizedBox(
                height: imageHeight,
                child: Container(
                  color: Colors.grey[900],
                  child: icon != null
                      ? Image.network(
                          icon,
                          fit: BoxFit.fill, // preserve aspect ratio while filling
                          alignment: Alignment.center,
                          errorBuilder: (c, e, st) => const Icon(Icons.broken_image),
                        )
                      : const Center(child: Icon(Icons.image, color: Colors.grey)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Цена — метка и значение в одной строке, значение выровнено вправо
            _keyValueRow('Цена:', Text(_formatPrice(price), style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.w700))),
            // Описание под ценой; описание остаётся слева
            const SizedBox(height: 8),
            Text('Описание', style: theme.textTheme.labelSmall),
            const SizedBox(height: 6),
            Text(description.isNotEmpty ? description : '—', style: theme.textTheme.bodyMedium),
          ]);
        }),

        // Специальные типы (не начинаются с новой строки после ':'), и остальные поля — как «ключ: значение», значение выровнено по правому краю
        if (specialTypes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: specialTypes.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 44, 44, 46),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('#$s', style: const TextStyle(color: Color(0xFFD9D9D9), fontSize: 13, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ),

        if (rarity != null) _keyValueRow('Редкость:', Text(rarity, style: theme.textTheme.bodyMedium)),

        if (weight != null) _keyValueRow('Вес:', Text(weight, style: theme.textTheme.bodyMedium)),

        if (weaponClasses.isNotEmpty) _keyValueRow('Класс оружия:', Text(weaponClasses.join(', '), style: theme.textTheme.bodyMedium)),

        if (weaponTypes.isNotEmpty) _keyValueRow('Тип оружия:', Text(weaponTypes.join(', '), style: theme.textTheme.bodyMedium)),

        // Урон оружия — карточки в два ряда
        if (hands.isNotEmpty)
          _maybeSection(
            'Урон оружия',
            Builder(builder: (context) {
              final grouped = <bool, List<Map<String, dynamic>>>{};
              for (final h in hands) {
                final key = h['hand_type'] as bool? ?? false;
                grouped.putIfAbsent(key, () => []).add(h);
              }
              final sortedKeys = grouped.keys.toList()..sort((a, b) => a == b ? 0 : (a ? 1 : -1));

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: sortedKeys.map((isTwoHanded) {
                  final rows = grouped[isTwoHanded]!;
                  final title = isTwoHanded ? 'Двуручный' : 'Одноручный';
                  return Container(
                    width: (MediaQuery.of(context).size.width - 48) / 2,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color.fromARGB(255, 40, 40, 40), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.labelSmall),
                        _damageInline(rows),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ),

        // Дальность поражения — соберём в одну строку и выровняем значение вправо
        if (ranges.isNotEmpty)
          _keyValueRow(
            'Дальность поражения:',
            Text(ranges.map((r) {
              final min = r['min_range']?.toString() ?? '';
              final max = r['max_range']?.toString() ?? '';
              return '$min - $max';
            }).join(', '), style: theme.textTheme.bodyMedium, textAlign: TextAlign.right),
          ),

        // Урон снаряда — одно значение, выровнено вправо
        if (ammos.isNotEmpty)
          _keyValueRow(
            'Урон снаряда:',
            _damageInline(ammos),
          ),

        // Доступный боезапас (показываем первые 3 карточки, остальные в раскрываемом списке)
        if (compatibleAmmos.isNotEmpty) ...[
          _maybeSection('Доступный боезапас', const SizedBox.shrink()),
          ...compatibleAmmos.take(3).map((a) => _ammoCard(a)),
          if (compatibleAmmos.length > 3) ...[
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _ammoExpanded
                  ? Column(
                children: compatibleAmmos.skip(3).map((a) => _ammoCard(a)).toList(),
              )
                  : const SizedBox.shrink(),
            ),
            GestureDetector(
              onTap: () => setState(() => _ammoExpanded = !_ammoExpanded),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Ещё ${compatibleAmmos.length - 3} боеприпасов',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: AnimatedRotation(
                      turns: _ammoExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: const Icon(
                        Icons.expand_more,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],

        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _ammoCard(Map<String, dynamic> a) {
    final name = a['name'] as String? ?? 'Без имени';
    final icon = a['icon'] as String?;
    final damages = (a['damages'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final min = a['min_range']?.toString() ?? '';
    final max = a['max_range']?.toString() ?? '';

    return Card(
      color: const Color.fromARGB(255, 40, 40, 40),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            color: Colors.grey[900],
            child: icon != null ? Image.network(icon, fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.broken_image)) : const Icon(Icons.image, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              _damageInline(damages),
              const SizedBox(height: 4),
              Text('Дальность: ${min.isNotEmpty || max.isNotEmpty ? '$min - $max' : '—'}', style: const TextStyle(color: Colors.white54)),
            ]),
          )
        ]),
      ),
    );
  }
}



