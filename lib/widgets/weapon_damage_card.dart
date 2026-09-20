import 'package:flutter/material.dart';

/// Одна строка урона: несколько типов урона на один кубик + бонус.
/// sort_order НЕ хранится здесь — вычисляется по индексу строки в списке при сборке payload.
class DamageRowData {
  Set<int> damageTypeIds;
  int diceMulti;
  int? diceId;
  int? dmgConst;

  DamageRowData({Set<int>? damageTypeIds, this.diceMulti = 1, this.diceId, this.dmgConst})
      : damageTypeIds = damageTypeIds ?? <int>{};
}

class WeaponDamageCard extends StatelessWidget {
  final String title; // 'Одноручный' | 'Двухручный'
  final bool required;
  final List<DamageRowData> rows;
  final List<Map<String, dynamic>> damageTypes; // LookupsController.damageTypes
  final List<Map<String, dynamic>> diceOptions;  // LookupsController.dice
  final VoidCallback onAddRow;
  final ValueChanged<int> onRemoveRow;
  final VoidCallback onChanged; // модели мутируются по ссылке, этот колбэк просто триггерит setState у родителя

  const WeaponDamageCard({
    super.key,
    required this.title,
    required this.required,
    required this.rows,
    required this.damageTypes,
    required this.diceOptions,
    required this.onAddRow,
    required this.onRemoveRow,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color.fromARGB(255, 40, 40, 40), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          if (required) const Padding(padding: EdgeInsets.only(left: 4), child: Text('*', style: TextStyle(color: Colors.redAccent))),
        ]),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Center(child: Padding(padding: EdgeInsets.only(top: 10, bottom: 4), child: Center(child: Icon(Icons.add, color: Colors.white54, size: 28)))),
          _DamageRow(row: rows[i], damageTypes: damageTypes, diceOptions: diceOptions, onChanged: onChanged),
          if (i > 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onRemoveRow(i),
                icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 18),
                label: const Text('Удалить строку', style: TextStyle(color: Colors.white54)),
              ),
            ),
        ],
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: onAddRow,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Добавить строку урона', style: TextStyle(fontSize: 15)), // было default ~13-14
          ),
        ),
      ]),
    );
  }
}

class _DamageRow extends StatelessWidget {
  final DamageRowData row;
  final List<Map<String, dynamic>> damageTypes;
  final List<Map<String, dynamic>> diceOptions;
  final VoidCallback onChanged;

  const _DamageRow({required this.row, required this.damageTypes, required this.diceOptions, required this.onChanged});

  Future<void> _pickDamageTypes(BuildContext context) async {
    final temp = Set<int>.from(row.damageTypeIds);
    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (dctx) => StatefulBuilder(builder: (ctx, setStateDialog) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
          title: const Text('Типы урона', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: damageTypes.map((t) {
                final id = t['id'] as int;
                return CheckboxListTile(
                  value: temp.contains(id),
                  title: Text(t['name'] as String? ?? '', style: const TextStyle(color: Colors.white)),
                  onChanged: (v) => setStateDialog(() => v == true ? temp.add(id) : temp.remove(id)),
                  activeColor: Colors.blueAccent,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dctx).pop(null), child: const Text('Отмена')),
            TextButton(onPressed: () => Navigator.of(dctx).pop(temp), child: const Text('Ок')),
          ],
        );
      }),
    );
    if (selected != null) {
      row.damageTypeIds..clear()..addAll(selected);
      onChanged();
    }
  }

  String _typesLabel() {
    final n = row.damageTypeIds.length;
    if (n == 0) return 'Тип урона';
    final mod10 = n % 10, mod100 = n % 100;
    final word = (mod10 == 1 && mod100 != 11) ? 'тип урона' : ([2, 3, 4].contains(mod10) && ![12, 13, 14].contains(mod100)) ? 'типа урона' : 'типов урона';
    return '$n $word';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FormField<Set<int>>(
          initialValue: row.damageTypeIds,
          validator: (v) => (v == null || v.isEmpty) ? 'Выберите тип урона' : null,
          builder: (field) => InkWell(
            onTap: () async {
              await _pickDamageTypes(context);
              field.didChange(row.damageTypeIds);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Тип урона',
                labelStyle: const TextStyle(color: Colors.white70),
                errorText: field.errorText,
              ),
              child: Text(_typesLabel(), style: const TextStyle(color: Colors.white)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: row.diceMulti.toString(),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Кол-во', labelStyle: TextStyle(color: Colors.white70)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательно' : null, // добавлено
              onChanged: (v) { row.diceMulti = int.tryParse(v) ?? row.diceMulti; onChanged(); },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              initialValue: row.diceId,
              decoration: const InputDecoration(labelText: 'Кубик', labelStyle: TextStyle(color: Colors.white70)),
              validator: (v) => v == null ? 'Выберите кубик' : null, // добавлено
              dropdownColor: const Color.fromRGBO(37, 37, 39, 1.0),
              style: const TextStyle(color: Colors.white),
              items: diceOptions.map((d) => DropdownMenuItem<int>(value: d['id'] as int, child: Text(d['name'] as String? ?? ''))).toList(),
              onChanged: (v) { row.diceId = v; onChanged(); },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: row.dmgConst?.toString() ?? '',
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Бонус', labelStyle: TextStyle(color: Colors.white70)),
              onChanged: (v) { row.dmgConst = int.tryParse(v); onChanged(); },
            ),
          ),
        ]),
      ]),
    );
  }
}