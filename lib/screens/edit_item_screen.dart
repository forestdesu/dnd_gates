import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../controllers/lookups.dart';
import '../widgets/weapon_fields_section.dart';
import '../widgets/weapon_damage_card.dart';
import '../widgets/image_gallery_picker.dart';
import '../utils/image_pick_and_crop.dart';
import 'community.dart' show Item;

class EditItemScreen extends StatefulWidget {
  final int itemId;
  final Map<String, dynamic> itemData;

  const EditItemScreen({super.key, required this.itemId, required this.itemData});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _weightController;
  List<Item> _selectedAmmo = [];
  final List<GalleryImage> _galleryImages = [];
  int? _rarityId;
  bool _saving = false;
  String? _error;

  late final bool _isWeapon;
  late final String _typeName;
  final Set<String> _weaponSpecialTypes = {};
  final List<DamageRowData> _oneHandedRows = [];
  final List<DamageRowData> _twoHandedRows = [];

  static const _labelStyle = TextStyle(color: Colors.white70);
  static const _textStyle = TextStyle(color: Colors.white);

  @override
  void initState() {
    super.initState();
    final d = widget.itemData;
    _nameController = TextEditingController(text: d['name'] as String? ?? '');
    _descriptionController = TextEditingController(text: d['description'] as String? ?? '');
    final images = (d['images'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    _galleryImages.addAll(images.map((i) => GalleryImage.server(id: i['id'] as int, url: i['url'] as String)));
    _priceController = TextEditingController(text: (d['price'] as int? ?? 0).toString());
    _weightController = TextEditingController(text: d['weight']?.toString() ?? '');

    final types = (d['types'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    _typeName = types.isNotEmpty ? (types.first['name'] as String? ?? '—') : '—';
    _isWeapon = _typeName == 'Оружие';

    final lookups = context.read<LookupsController>();
    final rarityMatch = lookups.rarities.firstWhere((r) => r['name'] == d['rarity'], orElse: () => {});
    _rarityId = rarityMatch['id'] as int?;

    if (_isWeapon) {
      final specialTypes = (d['special_types'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      _weaponSpecialTypes.addAll(specialTypes.map((e) => e['name'] as String? ?? '').where((s) => s.isNotEmpty));

      final hands = (d['hands'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      _oneHandedRows.addAll(_buildRows(hands, false, lookups));
      _twoHandedRows.addAll(_buildRows(hands, true, lookups));
      if (_oneHandedRows.isEmpty) _oneHandedRows.add(DamageRowData());
      if (_twoHandedRows.isEmpty) _twoHandedRows.add(DamageRowData());

      final compatibleAmmos = (d['compatible_ammos'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      _selectedAmmo = compatibleAmmos.map((a) => Item(
        id: a['id'] as int? ?? 0,
        name: a['name'] as String? ?? '',
        icon: a['icon'] as String?,
        rarity: '',
        price: 0,
        types: const [],
        specialTypes: const [],
      )).toList();
    }
  }

  List<DamageRowData> _buildRows(List<Map<String, dynamic>> hands, bool handType, LookupsController lookups) {
    final filtered = hands.where((h) => (h['hand_type'] as bool?) == handType).toList();
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final h in filtered) {
      final so = h['sort_order'] as int? ?? 0;
      grouped.putIfAbsent(so, () => []).add(h);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    return sortedKeys.map((so) {
      final rows = grouped[so]!;
      final ids = <int>{};
      for (final r in rows) {
        final match = lookups.damageTypes.firstWhere((t) => t['name'] == r['damage_type'], orElse: () => {});
        if (match['id'] != null) ids.add(match['id'] as int);
      }
      final first = rows.first;
      final diceMatch = lookups.dice.firstWhere((dd) => dd['name'] == first['dice_name'], orElse: () => {});
      return DamageRowData(
        damageTypeIds: ids,
        diceMulti: first['dice_multi'] as int? ?? 1,
        diceId: diceMatch['id'] as int?,
        dmgConst: first['dmg_const'] as int?,
      );
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _serializeDamageRows(List<DamageRowData> rows) {
    return rows.map((r) => {
      'damage_type_ids': r.damageTypeIds.toList(),
      'dice_multi': r.diceMulti,
      'dice_id': r.diceId,
      'dmg_const': r.dmgConst,
    }).toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _rarityId == null) {
      setState(() => _error = _rarityId == null ? 'Выберите редкость' : null);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final token = await ApiService.getToken();
    if (token == null) {
      setState(() {
        _saving = false;
        _error = 'Необходимо войти в аккаунт';
      });
      return;
    }

    try {
      final lookups = context.read<LookupsController>();
      final hasTwoHanded = _weaponSpecialTypes.contains('Двуручное') || _weaponSpecialTypes.contains('Универсальное');
      final isTwoHandedOnly = _weaponSpecialTypes.contains('Двуручное');

      final specialTypeIds = _weaponSpecialTypes
          .map((name) => lookups.properties.firstWhere((p) => p['name'] == name, orElse: () => {})['id'] as int?)
          .whereType<int>()
          .toList();

      final body = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'rarity_id': _rarityId,
        'price': int.tryParse(_priceController.text) ?? 0,
        'weight': double.tryParse(_weightController.text),
        if (_isWeapon) 'special_type_ids': specialTypeIds,
        if (_isWeapon && !isTwoHandedOnly) 'one_handed_damages': _serializeDamageRows(_oneHandedRows),
        if (_isWeapon && hasTwoHanded) 'two_handed_damages': _serializeDamageRows(_twoHandedRows),
        if (_isWeapon) 'ammo_item_ids': _selectedAmmo.map((i) => i.id).toList(),
      };
      final response = await ApiService.updateItem(token, widget.itemId, body);
      if (response.statusCode == 200) {
        final imageIds = _galleryImages.where((i) => i.id != null).map((i) => i.id!).toList();
        if (imageIds.isNotEmpty) {
          await ApiService.reorderItemImages(token, widget.itemId, imageIds);
        }
        if (mounted) Navigator.pop(context, true);
      } else {
        final resp = jsonDecode(response.body) as Map<String, dynamic>?;
        setState(() => _error = resp?['detail']?.toString() ?? 'Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Ошибка подключения: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: _labelStyle,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(132, 132, 137, 1.0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
    );
  }

  Future<void> _pickImage() async {
    if (_galleryImages.length >= 5) return;
    final file = await pickAndCropImage(context);
    if (file == null) return;
    final token = await ApiService.getToken();
    if (token == null) return;
    final response = await ApiService.uploadItemImage(token, widget.itemId, file);
    if (response.statusCode == 200 && mounted) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() => _galleryImages.add(GalleryImage.server(id: data['id'] as int, url: data['url'] as String)));
    } else if (mounted) {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data?['detail']?.toString() ?? 'Ошибка загрузки')));
    }
  }

  Future<void> _reorderImages(List<GalleryImage> updated) async {
    setState(() { _galleryImages..clear()..addAll(updated); });
    final token = await ApiService.getToken();
    if (token == null) return;
    final imageIds = updated.map((i) => i.id).whereType<int>().toList();
    await ApiService.reorderItemImages(token, widget.itemId, imageIds);
  }

  Future<void> _removeImage(GalleryImage img) async {
    if (img.id == null) return;
    final token = await ApiService.getToken();
    if (token == null) return;
    final response = await ApiService.deleteItemImage(token, widget.itemId, img.id!);
    if (response.statusCode == 200 && mounted) {
      setState(() => _galleryImages.remove(img));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookups = context.watch<LookupsController>();
    final rarities = lookups.rarities;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 31, 31, 31),
      appBar: AppBar(
        title: const Text('Редактирование'),
        backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ImageGalleryPicker(images: _galleryImages, onAdd: _pickImage, onRemove: _removeImage, onReorder: _reorderImages),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              style: _textStyle,
              decoration: _decoration('Название *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              style: _textStyle,
              maxLines: 3,
              decoration: _decoration('Описание'),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: _decoration('Тип предмета'),
              child: Text(_typeName, style: const TextStyle(color: Colors.white54)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _rarityId,
              decoration: _decoration('Редкость *'),
              dropdownColor: const Color.fromRGBO(37, 37, 39, 1.0),
              style: _textStyle,
              items: rarities
                  .map((r) => DropdownMenuItem<int>(value: r['id'] as int, child: Text(r['name'] as String? ?? '')))
                  .toList(),
              onChanged: (v) => setState(() => _rarityId = v),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  style: _textStyle,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Цена (мед.)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  style: _textStyle,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration('Вес'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            if (_isWeapon)
              WeaponFieldsSection(
                allSpecialTypes: lookups.properties,
                selectedSpecialTypes: _weaponSpecialTypes,
                onSpecialTypesChanged: (s) => setState(() { _weaponSpecialTypes..clear()..addAll(s); }),
                oneHandedRows: _oneHandedRows,
                twoHandedRows: _twoHandedRows,
                damageTypes: lookups.damageTypes,
                diceOptions: lookups.dice,
                onOneHandedAddRow: () => setState(() => _oneHandedRows.add(DamageRowData())),
                onOneHandedRemoveRow: (i) => setState(() => _oneHandedRows.removeAt(i)),
                onTwoHandedAddRow: () => setState(() => _twoHandedRows.add(DamageRowData())),
                onTwoHandedRemoveRow: (i) => setState(() => _twoHandedRows.removeAt(i)),
                onDamageChanged: () => setState(() {}),
                selectedAmmo: _selectedAmmo,
                onAmmoChanged: (items) => setState(() => _selectedAmmo = items),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Сохранить'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}