import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../controllers/items_update_notifier.dart';
import '../services/api_service.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/damage_display.dart';
import '../widgets/ammo_card.dart';
import '../utils/price_formatter.dart';
import 'edit_item_screen.dart';
import '../widgets/item_image.dart';
import '../widgets/item_card.dart' show rarityColors, RarityShimmerText;
import '../widgets/fullscreen_gallery.dart';
import '../controllers/auth.dart';
import 'subscription.dart' show GroupSettingsScreen;
import 'user_profile.dart';

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
  int _currentImagePage = 0;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _openEdit() async {
    if (data == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditItemScreen(itemId: widget.itemId, itemData: data!)),
    );
    if (updated == true) _load();
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
        title: const Text('Вы точно хотите удалить этот предмет?', style: TextStyle(color: Colors.white)),
        actions: [
          Row(children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Да'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Нет'),
              ),
            ),
          ]),
        ],
      ),
    );
    if (ok != true) return;

    final token = await ApiService.getToken();
    if (token == null) return;
    final response = await ApiService.deleteItem(token, widget.itemId);
    if (response.statusCode == 200 && mounted) {
      context.read<ItemsUpdateNotifier>().notifyItemsChanged();
      Navigator.pop(context, true);
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
    final auth = context.watch<AuthController>();
    final authors = (data?['authors'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final isOwner = auth.isAuthenticated &&
        (authors.any((a) => a['id'].toString() == auth.userProfile['id']) || auth.isStaff);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: isOwner
            ? [
          IconButton(icon: const Icon(Icons.edit), onPressed: _openEdit),
          IconButton(icon: const Icon(Icons.delete), onPressed: _confirmDelete),
        ]
            : null,
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
    final authors = (d['authors'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? []; // НОВОЕ
    final auth = context.watch<AuthController>();
    final specialTypes = (d['special_types'] as List<dynamic>?)?.map((e) => e['name'] as String? ?? '').where((s) => s.isNotEmpty).toList() ?? [];
    final weaponClasses = (d['weapon_classes'] as List<dynamic>?)?.map((e) => e['name'] as String? ?? '').where((s) => s.isNotEmpty).toList() ?? [];
    final weaponTypes = (d['weapon_types'] as List<dynamic>?)?.map((e) => e['name'] as String? ?? '').where((s) => s.isNotEmpty).toList() ?? [];
    final hands = (d['hands'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final ranges = (d['ranges'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final ammos = (d['ammos'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final compatibleAmmos = (d['compatible_ammos'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final images = (d['images'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final galleryUrls = images.isNotEmpty ? images.map((i) => i['url'] as String).toList() : (icon != null ? [icon] : <String>[]);

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _ImageGallery(
          urls: galleryUrls,
          currentPage: _currentImagePage,
          onPageChanged: (i) => setState(() => _currentImagePage = i),
          height: screenWidth,
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                if (auth.isAuthenticated) _AddToGroupButton(itemId: widget.itemId), // ИЗМЕНЕНО: теперь в Row рядом с именем
              ],
            ),
            _AuthorsRow(authors: authors),
            _keyValueRow('Цена:', Text(price.asPrice, style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.w700))),
            const SizedBox(height: 8),
            Text('Описание', style: theme.textTheme.labelSmall),
            const SizedBox(height: 6),
            Text(description.isNotEmpty ? description : '—', style: theme.textTheme.bodyMedium),

            if (specialTypes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: specialTypes.map((s) => InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context, {'filterSpecialType': s}),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 44, 44, 46),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('#$s', style: const TextStyle(color: Color(0xFFD9D9D9), fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  )).toList(),
                ),
              ),

            if (rarity != null)
              _keyValueRow('Редкость:', _RarityText(rarity, style: theme.textTheme.bodyMedium)),

            if (weight != null) _keyValueRow('Вес:', Text(weight, style: theme.textTheme.bodyMedium)),

            if (weaponClasses.isNotEmpty) _keyValueRow('Класс оружия:', Text(weaponClasses.join(', '), style: theme.textTheme.bodyMedium)),

            if (weaponTypes.isNotEmpty) _keyValueRow('Тип оружия:', Text(weaponTypes.join(', '), style: theme.textTheme.bodyMedium)),

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
                            DamageInline(rows),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }),
              ),

            if (ranges.isNotEmpty)
              _keyValueRow(
                'Дальность поражения:',
                Text(ranges.map((r) {
                  final min = r['min_range']?.toString() ?? '';
                  final max = r['max_range']?.toString() ?? '';
                  return '$min - $max';
                }).join(', '), style: theme.textTheme.bodyMedium, textAlign: TextAlign.right),
              ),

            if (ammos.isNotEmpty)
              _keyValueRow(
                'Урон снаряда:',
                DamageInline(ammos),
              ),

            if (compatibleAmmos.isNotEmpty) ...[
              _maybeSection('Доступный боезапас', const SizedBox.shrink()),
              ...compatibleAmmos.take(3).map((a) => AmmoCard(a)),
              if (compatibleAmmos.length > 3) ...[
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _ammoExpanded
                      ? Column(
                    children: compatibleAmmos.skip(3).map((a) => AmmoCard(a)).toList(),
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
                          style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: AnimatedRotation(
                          turns: _ammoExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: const Icon(Icons.expand_more, color: Colors.white70, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),
          ]),
        ),
      ]),
    );
  }

}

class _ImageGallery extends StatelessWidget {
  final List<String> urls;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final double height;

  const _ImageGallery({required this.urls, required this.currentPage, required this.onPageChanged, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(children: [
        Positioned.fill(
          child: urls.isEmpty
              ? const ItemImage(url: null, fit: BoxFit.fill)
              : PageView(
            onPageChanged: onPageChanged,
            children: [
              for (final url in urls)
                GestureDetector(
                  onTap: () => Navigator.of(context).push(PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black,
                    pageBuilder: (_, __, ___) => FullscreenGallery(urls: urls, initialIndex: urls.indexOf(url)),
                  )),
                  child: Hero(
                    tag: 'item_image_$url',
                    child: Image.network(url, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (c, e, st) => const ItemImage(url: null, fit: BoxFit.fill)),
                  ),
                ),
            ],
          ),
        ),
        if (urls.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(160, 31, 31, 31),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var i = 0; i < urls.length; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: i == currentPage ? Colors.red : Colors.white24),
                    ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _RarityText extends StatelessWidget {
  final String rarity;
  final TextStyle? style;

  const _RarityText(this.rarity, {this.style});

  @override
  Widget build(BuildContext context) {
    if (rarity == 'Редкость варьируется') {
      return RarityShimmerText(rarity, style: style);
    }
    return Text(rarity, style: style?.copyWith(color: rarityColors[rarity] ?? Colors.white));
  }
}

class _AuthorsRow extends StatelessWidget {
  final List<Map<String, dynamic>> authors;
  const _AuthorsRow({required this.authors});

  @override
  Widget build(BuildContext context) {
    if (authors.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < authors.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _AuthorChip(author: authors[i]),
          ],
        ],
      ),
    );
  }
}

class _AuthorChip extends StatelessWidget {
  final Map<String, dynamic> author;
  const _AuthorChip({required this.author});

  @override
  Widget build(BuildContext context) {
    final name = author['name'] as String? ?? '';
    final img = author['img'] as String?;
    final worksCount = author['works_count']?.toString() ?? '0';
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfileScreen(userId: author['id'] as int)),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Row(children: [
        ClipOval(child: SizedBox(width: 60, height: 60, child: ItemImage(url: img))),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              Text('$worksCount работ', style: const TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _GroupEntry {
  final int id;
  final String name;
  final bool alreadyAdded;
  _GroupEntry({required this.id, required this.name, required this.alreadyAdded});
  factory _GroupEntry.fromJson(Map<String, dynamic> json) => _GroupEntry(
        id: json['id'] as int,
        name: json['name'] as String,
        alreadyAdded: json['already_added'] as bool? ?? false,
      );
}

class _AddToGroupButton extends StatefulWidget {
  final int itemId;
  const _AddToGroupButton({required this.itemId});

  @override
  State<_AddToGroupButton> createState() => _AddToGroupButtonState();

}

class _AddToGroupButtonState extends State<_AddToGroupButton> {
  Future<void> _open() async {
    final token = await ApiService.getToken();
    if (token == null || !mounted) return;

    List<_GroupEntry> groups;
    try {
      final response = await ApiService.getMyGroups(token, itemId: widget.itemId);
      if (response.statusCode != 200) throw Exception();
      final data = jsonDecode(response.body) as List<dynamic>;
      groups = data.map((g) => _GroupEntry.fromJson(g as Map<String, dynamic>)).toList();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось загрузить группы')));
      return;
    }
    if (!mounted) return;

    if (groups.isEmpty) {
      final goCreate = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
          title: const Text('У вас пока нет групп', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Создать группу')),
          ],
        ),
      );
      if (goCreate == true && mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GroupSettingsScreen()));
      }
      return;
    }

    // ИЗМЕНЕНО: selected теперь стартует с уже добавленных групп, а не пустой
    final selected = groups.where((g) => g.alreadyAdded).map((g) => g.id).toSet();
    final initiallyAdded = Set<int>.from(selected); // НОВОЕ: снимок исходного состояния для вычисления диффа

    await showDialog<void>(
      context: context,
      builder: (dctx) => StatefulBuilder(builder: (ctx, setStateDialog) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
          title: const Text('Добавить в группу', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: groups.map((g) => CheckboxListTile(
                value: selected.contains(g.id), // ИЗМЕНЕНО: g.alreadyAdded больше не форсит true напрямую
                title: Text(g.name, style: const TextStyle(color: Colors.white)),
                onChanged: (v) => setStateDialog(() => v == true ? selected.add(g.id) : selected.remove(g.id)), // ИЗМЕНЕНО: чекбокс кликабелен всегда
                activeColor: Colors.blueAccent,
                controlAffinity: ListTileControlAffinity.leading,
              )).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async { // ИЗМЕНЕНО: убрана проверка selected.isEmpty — теперь можно только снимать
                final toAdd = selected.difference(initiallyAdded).toList();
                final toRemove = initiallyAdded.difference(selected).toList();
                if (toAdd.isNotEmpty) {
                  await ApiService.addItemToGroups(token, widget.itemId, toAdd);
                }
                for (final groupId in toRemove) {
                  await ApiService.removeGroupItem(token, groupId, widget.itemId);
                }
                if (dctx.mounted) Navigator.of(dctx).pop();
              },
              child: const Text('Сохранить'), // ИЗМЕНЕНО: "Добавить" -> "Сохранить", т.к. теперь и снимает тоже
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _open,
      icon: const Icon(Icons.playlist_add, color: Colors.white, size: 30), // ИЗМЕНЕНО: только иконка, крупнее
      tooltip: 'Добавить в группу',
    );
  }
}
