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

class CreateItemScreen extends StatefulWidget {
  const CreateItemScreen({super.key});

  @override
  State<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends State<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _weightController = TextEditingController(text: '1');
  List<Item> _selectedAmmo = [];
  final List<GalleryImage> _galleryImages = [];
  int? _rarityId;
  bool _saving = false;
  String? _error;

  int? _itemTypeId;
  final Set<String> _weaponSpecialTypes = {};
  final List<DamageRowData> _oneHandedRows = [DamageRowData()];
  final List<DamageRowData> _twoHandedRows = [DamageRowData()];

  static const _labelStyle = TextStyle(color: Colors.white70);
  static const _textStyle = TextStyle(color: Colors.white);

  String? _selectedTypeName(List<Map<String, dynamic>> types) {
    if (_itemTypeId == null) return null;
    final found = types.firstWhere((t) => t['id'] == _itemTypeId, orElse: () => {});
    return found['name'] as String?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await pickAndCropImage(context);
    if (file == null) return;
    setState(() => _galleryImages.add(GalleryImage.local(file)));
  }

  void _removeImage(GalleryImage img) {
    setState(() => _galleryImages.remove(img));
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
      final selectedTypeName = _selectedTypeName(lookups.types);
      final isWeapon = selectedTypeName == 'Оружие';
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
        if (isWeapon) 'item_type_id': _itemTypeId,
        if (isWeapon) 'special_type_ids': specialTypeIds,
        if (isWeapon && !isTwoHandedOnly) 'one_handed_damages': _serializeDamageRows(_oneHandedRows),
        if (isWeapon && hasTwoHanded) 'two_handed_damages': _serializeDamageRows(_twoHandedRows),
        if (isWeapon) 'ammo_item_ids': _selectedAmmo.map((i) => i.id).toList(),
      };
      final response = await ApiService.createItem(token, body);
      if (response.statusCode == 200) {
        final created = jsonDecode(response.body) as Map<String, dynamic>;
        final newItemId = created['id'] as int;
        for (final img in _galleryImages) {
          if (img.localFile != null) {
            await ApiService.uploadItemImage(token, newItemId, img.localFile!);
          }
        }
        if (mounted) Navigator.pop(context, true);
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        setState(() => _error = data?['detail']?.toString() ?? 'Ошибка сервера: ${response.statusCode}');
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

  List<Map<String, dynamic>> _serializeDamageRows(List<DamageRowData> rows) {
    return rows.map((r) => {
      'damage_type_ids': r.damageTypeIds.toList(),
      'dice_multi': r.diceMulti,
      'dice_id': r.diceId,
      'dmg_const': r.dmgConst,
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lookups = context.watch<LookupsController>();
    final rarities = lookups.rarities;
    final types = lookups.types;
    final selectedTypeName = _selectedTypeName(types);
    final isWeapon = selectedTypeName == 'Оружие';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 31, 31, 31),
      appBar: AppBar(
        title: const Text('Новая работа'),
        backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ImageGalleryPicker(images: _galleryImages, onAdd: _pickImage, onRemove: _removeImage, onReorder: (u) => setState(() { _galleryImages..clear()..addAll(u); })),
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
            DropdownButtonFormField<int>(
              initialValue: _itemTypeId,
              decoration: _decoration('Тип предмета *'),
              dropdownColor: const Color.fromRGBO(37, 37, 39, 1.0),
              style: _textStyle,
              items: types.map((t) => DropdownMenuItem<int>(value: t['id'] as int, child: Text(t['name'] as String? ?? ''))).toList(),
              onChanged: (v) => setState(() => _itemTypeId = v),
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
            if (isWeapon)
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
            const SizedBox(height: 12),

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
                    : const Text('Создать'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}