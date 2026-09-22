import 'package:flutter/material.dart';

const Map<String, Set<String>> weaponSpecialTypeConflicts = {
  'Лёгкое': {'Перезарядка', 'Универсальное', 'Боеприпас', 'Двуручное'},
  'Тяжелое': {'Фехтовальное', 'Перезарядка', 'Боеприпас', 'Метательное'},
  'Фехтовальное': {'Тяжелое', 'Перезарядка', 'Боеприпас', 'Двуручное'},
  'Досягаемость': {'Перезарядка', 'Боеприпас', 'Метательное'},
  'Особое': {},
  'Перезарядка': {'Лёгкое', 'Тяжелое', 'Фехтовальное', 'Досягаемость', 'Универсальное', 'Метательное', 'Двуручное'},
  'Универсальное': {'Лёгкое', 'Перезарядка', 'Боеприпас', 'Метательное', 'Двуручное'},
  'Боеприпас': {'Лёгкое', 'Тяжелое', 'Фехтовальное', 'Досягаемость', 'Универсальное', 'Метательное', 'Двуручное'},
  'Метательное': {'Тяжелое', 'Досягаемость', 'Перезарядка', 'Универсальное', 'Боеприпас', 'Двуручное'},
  'Двуручное': {'Лёгкое', 'Фехтовальное', 'Перезарядка', 'Универсальное', 'Боеприпас', 'Метательное'},
};

const Map<String, Set<String>> weaponSpecialTypeRequires = {
  'Перезарядка': {'Боеприпас'},
};

class WeaponSpecialTypesPicker extends StatelessWidget {
  final List<Map<String, dynamic>> allTypes;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const WeaponSpecialTypesPicker({
    super.key,
    required this.allTypes,
    required this.selected,
    required this.onChanged,
  });

  Set<String> get _blocked {
    final blocked = <String>{};
    for (final name in selected) {
      blocked.addAll(weaponSpecialTypeConflicts[name] ?? const {});
    }
    for (final entry in weaponSpecialTypeRequires.entries) {
      final needsAny = entry.value;
      final satisfied = needsAny.any(selected.contains);
      if (!satisfied) blocked.add(entry.key);
    }
    blocked.removeAll(selected);
    return blocked;
  }

  void _toggle(String name) {
    final blocked = _blocked;
    if (selected.contains(name)) {
      onChanged({...selected}..remove(name));
    } else if (!blocked.contains(name)) {
      onChanged({...selected, name});
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _blocked;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allTypes.map((t) {
        final name = t['name'] as String? ?? '';
        return _SpecialTypeChip(
          label: name,
          selected: selected.contains(name),
          blocked: blocked.contains(name),
          onTap: () => _toggle(name),
        );
      }).toList(),
    );
  }
}

class _SpecialTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool blocked;
  final VoidCallback onTap;

  const _SpecialTypeChip({
    required this.label,
    required this.selected,
    required this.blocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? Colors.white : const Color.fromARGB(255, 40, 40, 40);
    final Color fg = selected ? Colors.black : (blocked ? Colors.redAccent : Colors.white);
    final Color border = selected ? Colors.white : (blocked ? Colors.redAccent : Colors.white24);

    return InkWell(
      onTap: blocked ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // было 14/8
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
        child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }
}