import 'package:flutter/material.dart';
import '../screens/community.dart' show Item;
import 'weapon_special_types_picker.dart';
import 'weapon_damage_card.dart';
import 'ammo_picker.dart';

const _sectionTitle = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700);

/// Блок формы создания оружия: спец-типы, урон, боезапас.
/// Состояние (списки строк урона, выбранные типы/боеприпасы) хранит родитель —
/// этот виджет только рисует UI и дёргает колбэки (как WeaponDamageCard/AmmoPicker).
class WeaponFieldsSection extends StatelessWidget {
  final List<Map<String, dynamic>> allSpecialTypes;
  final Set<String> selectedSpecialTypes;
  final ValueChanged<Set<String>> onSpecialTypesChanged;

  final List<DamageRowData> oneHandedRows;
  final List<DamageRowData> twoHandedRows;
  final List<Map<String, dynamic>> damageTypes;
  final List<Map<String, dynamic>> diceOptions;
  final VoidCallback onOneHandedAddRow;
  final ValueChanged<int> onOneHandedRemoveRow;
  final VoidCallback onTwoHandedAddRow;
  final ValueChanged<int> onTwoHandedRemoveRow;
  final VoidCallback onDamageChanged;

  final List<Item> selectedAmmo;
  final ValueChanged<List<Item>> onAmmoChanged;

  const WeaponFieldsSection({
    super.key,
    required this.allSpecialTypes,
    required this.selectedSpecialTypes,
    required this.onSpecialTypesChanged,
    required this.oneHandedRows,
    required this.twoHandedRows,
    required this.damageTypes,
    required this.diceOptions,
    required this.onOneHandedAddRow,
    required this.onOneHandedRemoveRow,
    required this.onTwoHandedAddRow,
    required this.onTwoHandedRemoveRow,
    required this.onDamageChanged,
    required this.selectedAmmo,
    required this.onAmmoChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Единственное место, где считается эта логика — раньше дублировалась и глючила в create_item_screen.
    final hasTwoHanded = selectedSpecialTypes.contains('Двуручное') || selectedSpecialTypes.contains('Универсальное');
    final hasAmmo = selectedSpecialTypes.contains('Боеприпас');
    final isTwoHandedOnly = selectedSpecialTypes.contains('Двуручное');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      const Text('Специальные типы оружия', style: _sectionTitle),
      const SizedBox(height: 8),
      WeaponSpecialTypesPicker(allTypes: allSpecialTypes, selected: selectedSpecialTypes, onChanged: onSpecialTypesChanged),
      const SizedBox(height: 16),
      const Text('Урон оружия', style: _sectionTitle),
      const SizedBox(height: 8),
      if (!isTwoHandedOnly)
        WeaponDamageCard(
          title: 'Одноручный',
          required: true,
          rows: oneHandedRows,
          damageTypes: damageTypes,
          diceOptions: diceOptions,
          onAddRow: onOneHandedAddRow,
          onRemoveRow: onOneHandedRemoveRow,
          onChanged: onDamageChanged,
        ),
      if (hasTwoHanded)
        WeaponDamageCard(
          title: 'Двухручный',
          required: true,
          rows: twoHandedRows,
          damageTypes: damageTypes,
          diceOptions: diceOptions,
          onAddRow: onTwoHandedAddRow,
          onRemoveRow: onTwoHandedRemoveRow,
          onChanged: onDamageChanged,
        ),
      if (hasAmmo)
        FormField<List<Item>>(
          initialValue: selectedAmmo,
          validator: (v) => (v == null || v.isEmpty) ? 'Выберите хотя бы один боеприпас' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmmoPicker(
                selected: selectedAmmo,
                onChanged: (items) {
                  onAmmoChanged(items);
                  field.didChange(items);
                },
              ),
              if (field.errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(field.errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
            ],
          ),
        ),
    ]);
  }
}