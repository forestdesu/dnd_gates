import 'package:flutter/material.dart';

class MultiSelectFilter {
  final String label;
  final Set<String> options;
  final Set<String> selected;
  MultiSelectFilter({required this.label, required this.options, required this.selected});
}

Future<void> _editMultiSelect(BuildContext context, MultiSelectFilter filter, VoidCallback onChanged) async {
  final temp = Set<String>.from(filter.selected);
  final selected = await showDialog<Set<String>>(
    context: context,
    builder: (dctx) {
      return StatefulBuilder(builder: (ctx, setStateDialog) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
          title: Text(filter.label, style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: filter.options.map((o) {
                return CheckboxListTile(
                  value: temp.contains(o),
                  title: Text(o, style: const TextStyle(color: Colors.white)),
                  onChanged: (v) => setStateDialog(() => v == true ? temp.add(o) : temp.remove(o)),
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
      });
    },
  );
  if (selected != null) {
    filter.selected..clear()..addAll(selected);
    onChanged();
  }
}

Future<void> showFiltersSheet(
    BuildContext context, {
      required List<MultiSelectFilter> multiSelectFilters,
      required String priceLabel,
      required TextEditingController priceFromController,
      required TextEditingController priceToController,
      required VoidCallback onReset,
      required VoidCallback onApply,
    }) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color.fromARGB(255, 31, 31, 31),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(builder: (context, setStateSheet) {
          final headerStyle = const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700);
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Фильтры', style: headerStyle),
                IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.of(context).pop()),
              ]),
              const Divider(color: Colors.white12),
              for (final filter in multiSelectFilters)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(filter.label, style: headerStyle),
                  trailing: Text(
                    filter.selected.isEmpty ? 'Любые' : '${filter.selected.length} выбрано',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () => _editMultiSelect(context, filter, () => setStateSheet(() {})),
                ),
              const SizedBox(height: 16),
              Text(priceLabel, style: headerStyle),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: priceFromController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'От',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(132, 132, 137, 1.0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(132, 132, 137, 1.0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(132, 132, 137, 1.0))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: priceToController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'До',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(132, 132, 137, 1.0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(132, 132, 137, 1.0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(132, 132, 137, 1.0))),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      style: TextButton.styleFrom(backgroundColor: Colors.transparent, side: const BorderSide(color: Colors.white12)),
                      onPressed: () {
                        onReset();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Сбросить', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        onApply();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Применить'),
                    ),
                  ),
                ),
              ]),
            ]),
          );
        }),
      );
    },
  );
}