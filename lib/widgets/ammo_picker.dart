import 'package:flutter/material.dart';
import '../screens/ammo_picker.dart';
import '../screens/community.dart' show Item;

class AmmoPicker extends StatelessWidget {
  final List<Item> selected;
  final ValueChanged<List<Item>> onChanged;

  const AmmoPicker({super.key, required this.selected, required this.onChanged});

  Future<void> _open(BuildContext context) async {
    final result = await Navigator.of(context).push<List<Item>>(
      MaterialPageRoute(builder: (_) => AmmoPickerScreen(initialSelected: selected)), // было initialSelectedIds: selected.map(...).toSet()
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color.fromARGB(255, 40, 40, 40), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Доступный боезапас', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _open(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color.fromARGB(255, 31, 31, 31), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
            child: Row(children: [
              const Icon(Icons.search, color: Colors.white38),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected.isEmpty ? 'Выбрать боеприпасы' : 'Выбрано: ${selected.length}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}