import 'package:flutter/material.dart';
import '../widgets/loading_indicator.dart';
import 'community.dart' show Item, fetchItemsPage;

class SubGroup {
  final String id;
  String name;
  bool isDraft;
  SubGroup({required this.id, required this.name, this.isDraft = false});
}

// ==================== Главный экран вкладки ====================

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Мок-данные групп на время макета
  List<SubGroup> _groups = [
    SubGroup(id: 'g1', name: 'Оружие'),
    SubGroup(id: 'g2', name: 'Броня'),
    SubGroup(id: 'g3', name: 'Зелья'),
  ];
  String? _selectedGroupId;

  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await fetchItemsPage(1, pageSize: 30);
      setState(() {
        _items = (data['items'] as List<Item>?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context).push<List<SubGroup>>(
      MaterialPageRoute(builder: (_) => GroupSettingsScreen(groups: _groups)),
    );
    if (updated != null) {
      setState(() => _groups = updated);
    }
  }

  void _toggleSelect(String id) {
    setState(() => _selectedGroupId = _selectedGroupId == id ? null : id);
  }

  // база + пользовательские группы; выбранная группа переезжает в начало (обходя базу)
  List<_RowEntry> get _displayRow {
    final base = _RowEntry(id: 'base', name: 'База');
    final userEntries = _groups.map((g) => _RowEntry(id: g.id, name: g.name)).toList();
    var all = [base, ...userEntries];
    if (_selectedGroupId != null) {
      final selected = all.firstWhere((e) => e.id == _selectedGroupId);
      all = [selected, ...all.where((e) => e.id != _selectedGroupId)];
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: const Color.fromRGBO(37, 37, 39, 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Поиск предметов...',
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            filled: true,
            fillColor: const Color.fromRGBO(45, 45, 47, 1.0),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          itemCount: _displayRow.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            if (i == 0) return _GearButton(onTap: _openSettings);
            final entry = _displayRow[i - 1];
            return _GroupChip(
              label: entry.name,
              selected: _selectedGroupId == entry.id,
              onTap: () => _toggleSelect(entry.id),
            );
          },
        ),
      ),
      Expanded(
        child: _error != null
            ? Center(child: Text('Ошибка: $_error', style: const TextStyle(color: Colors.white)))
            : ListView.builder(
          itemCount: _items.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == _items.length) {
              return const Padding(padding: EdgeInsets.all(16), child: Center(child: LoadingIndicator(size: 60)));
            }
            final item = _items[i];
            return ListTile(
              title: Text(item.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(item.rarity, style: const TextStyle(color: Colors.white54)),
            );
          },
        ),
      ),
    ]);
  }
}

class _RowEntry {
  final String id;
  final String name;
  _RowEntry({required this.id, required this.name});
}

class _GearButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Color.fromARGB(255, 40, 40, 40), shape: BoxShape.circle),
        child: const Icon(Icons.settings, color: Colors.white70, size: 20),
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GroupChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.red : const Color.fromARGB(255, 40, 40, 40),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: Colors.white, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }
}

// ==================== Экран настройки групп ====================

class GroupSettingsScreen extends StatefulWidget {
  final List<SubGroup> groups;
  const GroupSettingsScreen({super.key, required this.groups});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late List<SubGroup> _groups;
  final _searchController = TextEditingController();
  String? _editingId;
  final Map<String, TextEditingController> _editControllers = {};

  @override
  void initState() {
    super.initState();
    _groups = List<SubGroup>.from(widget.groups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _editControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<SubGroup> get _filtered => _searchController.text.isEmpty
      ? _groups
      : _groups.where((g) => g.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

  void _startEdit(SubGroup g) {
    _editControllers[g.id] = TextEditingController(text: g.name);
    setState(() => _editingId = g.id);
  }

  void _confirmEdit(SubGroup g) {
    final controller = _editControllers[g.id];
    setState(() {
      if (controller != null && controller.text.trim().isNotEmpty) {
        g.name = controller.text.trim();
      }
      g.isDraft = false;
      _editingId = null;
    });
    controller?.dispose();
    _editControllers.remove(g.id);
    // TODO: отправить запрос на создание/сохранение группы
  }

  Future<void> _confirmDelete(SubGroup g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
        title: Text('Вы точно хотите удалить группу "${g.name}"?', style: const TextStyle(color: Colors.white)),
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
    if (ok == true) {
      setState(() => _groups.removeWhere((e) => e.id == g.id));
      // TODO: отправить запрос на удаление группы
    }
  }

  void _addDraft() {
    final id = 'draft_${DateTime.now().microsecondsSinceEpoch}';
    final draft = SubGroup(id: id, name: 'Новая группа', isDraft: true);
    setState(() => _groups.add(draft));
    _startEdit(draft);
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _groups.removeAt(oldIndex);
      _groups.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 31, 31, 31),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(_groups),
              ),
              const Text('Настройка групп', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Поиск групп...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color.fromRGBO(45, 45, 47, 1.0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const _BaseGroupCard(),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filtered.length,
              onReorder: _reorder,
              itemBuilder: (context, index) {
                final g = _filtered[index];
                final editing = _editingId == g.id;
                return _GroupCard(
                  key: ValueKey(g.id),
                  index: index,
                  group: g,
                  editing: editing,
                  controller: _editControllers[g.id],
                  onEdit: () => _startEdit(g),
                  onConfirm: () => _confirmEdit(g),
                  onDelete: () => _confirmDelete(g),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Добавить группу'),
                onPressed: _addDraft,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _BaseGroupCard extends StatelessWidget {
  const _BaseGroupCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: const Color.fromARGB(255, 40, 40, 40), borderRadius: BorderRadius.circular(8)),
        child: const Text('База', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final int index;
  final SubGroup group;
  final bool editing;
  final TextEditingController? controller;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;
  final VoidCallback onDelete;

  const _GroupCard({
    super.key,
    required this.index,
    required this.group,
    required this.editing,
    required this.controller,
    required this.onEdit,
    required this.onConfirm,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(color: const Color.fromARGB(255, 40, 40, 40), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.drag_handle, color: Colors.white54),
            ),
          ),
          Expanded(
            child: editing
                ? TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
            )
                : Text(group.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          IconButton(
            icon: Icon(editing ? Icons.check : Icons.edit, color: editing ? Colors.green : Colors.white70),
            onPressed: editing ? onConfirm : onEdit,
          ),
          if (!group.isDraft)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white70),
              onPressed: onDelete,
            ),
        ]),
      ),
    );
  }
}