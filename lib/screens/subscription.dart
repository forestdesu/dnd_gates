import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../widgets/loading_indicator.dart';
import '../services/api_service.dart';
import 'community.dart' show Item;
import '../widgets/item_image.dart';
import 'item_detail.dart';
import '../controllers/items_update_notifier.dart';

class Group {
  final int id;
  final String name;
  final bool isBase;
  Group({required this.id, required this.name, required this.isBase});

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id'] as int,
    name: json['name'] as String,
    isBase: json['is_base'] as bool? ?? false,
  );
}

Future<List<Group>> fetchMyGroups(String token) async {
  try {
    final response = await ApiService.getMyGroups(token);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((g) => Group.fromJson(g as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Ошибка загрузки групп: ${response.statusCode}');
    }
  } on Exception {
    rethrow;
  } catch (e) {
    throw Exception('Ошибка подключения: $e');
  }
}

Future<Map<String, dynamic>> fetchGroupItemsPage(String token, int groupId, int page, {int pageSize = 30}) async {
  try {
    final response = await ApiService.getGroupItems(token, groupId, page, pageSize);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>?)
          ?.map((item) => Item.fromJson(item as Map<String, dynamic>))
          .toList() ?? [];
      return {
        'items': items,
        'page': data['page'] as int? ?? page,
        'total_pages': data['total_pages'] as int? ?? 0,
      };
    } else {
      throw Exception('Ошибка загрузки предметов группы: ${response.statusCode}');
    }
  } on Exception {
    rethrow;
  } catch (e) {
    throw Exception('Ошибка подключения: $e');
  }
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final ItemsUpdateNotifier _itemsUpdateNotifier;

  List<Group> _groups = [];
  bool _groupsLoading = true;
  String? _groupsError;
  int? _selectedGroupId;

  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _itemsUpdateNotifier = context.read<ItemsUpdateNotifier>();
    _itemsUpdateNotifier.addListener(_onItemsChanged);
  }

  @override
  void dispose() {
    _itemsUpdateNotifier.removeListener(_onItemsChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onItemsChanged() {
    if (_selectedGroupId != null) _selectGroup(_selectedGroupId!, isBase: _isBaseSelected);
  }

  Future<void> _removeItem(Item item) async {
    if (_selectedGroupId == null) return;
    final token = await ApiService.getToken();
    if (token == null) return;
    try {
      final response = await ApiService.removeGroupItem(token, _selectedGroupId!, item.id);
      if (response.statusCode == 200) {
        if (mounted) setState(() => _items.removeWhere((i) => i.id == item.id));
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data?['detail']?.toString() ?? 'Ошибка удаления: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка подключения: $e')));
    }
  }

  Future<void> _openItem(Item item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailPage(
          itemId: item.id,
          initialName: item.name,
          initialImageUrl: item.icon,
        ),
      ),
    );
  }

  Future<void> _loadGroups() async {
    final token = await ApiService.getToken();
    if (token == null) {
      setState(() {
        _groupsLoading = false;
        _groupsError = 'Необходимо войти в аккаунт';
      });
      return;
    }
    setState(() {
      _groupsLoading = true;
      _groupsError = null;
    });
    try {
      final groups = await fetchMyGroups(token);
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _groupsLoading = false;
      });
      if (groups.isNotEmpty) {
        final base = groups.firstWhere((g) => g.isBase, orElse: () => groups.first);
        _selectGroup(base.id, isBase: base.isBase);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _groupsError = e.toString();
        _groupsLoading = false;
      });
    }
  }

  bool _isBaseSelected = false;

  Future<void> _selectGroup(int groupId, {bool isBase = false}) async {
    setState(() {
      _selectedGroupId = groupId;
      _isLoading = true;
      _isBaseSelected = isBase;
      _error = null;
      _items = [];
    });
    final token = await ApiService.getToken();
    if (token == null) {
      setState(() { _isLoading = false; _error = 'Необходимо войти в аккаунт'; });
      return;
    }
    try {
      final data = await fetchGroupItemsPage(token, groupId, 1);
      if (!mounted) return;
      setState(() {
        _items = (data['items'] as List<Item>?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _openSettings() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const GroupSettingsScreen()),
    );
    if (changed == true) _loadGroups();
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
        child: _groupsLoading
            ? const Center(child: LoadingIndicator(size: 32))
            : ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          itemCount: _groups.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            if (i == 0) return _GearButton(onTap: _openSettings);
            final group = _groups[i - 1];
            return _GroupChip(
              label: group.name,
              selected: _selectedGroupId == group.id,
              onTap: () => _selectGroup(group.id, isBase: group.isBase),
            );
          },
        ),
      ),
      Expanded(
        child: _error != null
            ? Center(child: Text('Ошибка: $_error', style: const TextStyle(color: Colors.white)))
            : (_items.isEmpty && !_isLoading
            ? const Center(child: Text('В группе пока нет предметов', style: TextStyle(color: Colors.white)))
            : ListView.builder(
          itemCount: _items.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == _items.length) {
              return const Padding(padding: EdgeInsets.all(16), child: Center(child: LoadingIndicator(size: 60)));
            }
            final item = _items[i];
            return _GroupItemCard(
              item: item,
              showDelete: !_isBaseSelected,
              onTap: () => _openItem(item), // НОВОЕ
              onDelete: () => _removeItem(item),
            );
          },
        )),
      ),
    ]);
  }
}

class _GroupItemCard extends StatelessWidget {
  final Item item;
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GroupItemCard({required this.item, required this.showDelete, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onTap,
        child: Card(
          color: const Color.fromARGB(255, 40, 40, 40),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 100,
            child: Row(children: [
              SizedBox(width: 100, height: double.infinity, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: ItemImage(url: item.icon, fit: BoxFit.fill))),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.name, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('Редкость: ${item.rarity}', style: theme.textTheme.labelSmall),
                          ]),
                      if (showDelete) // НОВОЕ: вместо статус-бейджа из MyItemCard
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white70),
                          onPressed: onDelete,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
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

class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({super.key});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  List<Group> _groups = [];
  bool _loading = true;
  String? _error;
  bool _changed = false;
  final _searchController = TextEditingController();
  int? _editingGroupId;
  final Map<int, TextEditingController> _editControllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _editControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final token = await ApiService.getToken();
    if (token == null) {
      setState(() { _loading = false; _error = 'Необходимо войти в аккаунт'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final groups = await fetchMyGroups(token);
      if (!mounted) return;
      setState(() { _groups = groups; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Group> get _filtered => _searchController.text.isEmpty
      ? _groups
      : _groups.where((g) => g.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

  void _startEdit(Group g) {
    _editControllers[g.id] = TextEditingController(text: g.name);
    setState(() => _editingGroupId = g.id);
  }

  Future<void> _confirmEdit(Group g) async {
    final controller = _editControllers[g.id];
    final newName = controller?.text.trim();
    setState(() => _editingGroupId = null);
    controller?.dispose();
    _editControllers.remove(g.id);
    if (newName == null || newName.isEmpty || newName == g.name) return;

    final token = await ApiService.getToken();
    if (token == null) return;
    final response = await ApiService.renameGroup(token, g.id, newName);
    if (response.statusCode == 200 && mounted) {
      final idx = _groups.indexWhere((e) => e.id == g.id);
      setState(() {
        if (idx != -1) _groups[idx] = Group(id: g.id, name: newName, isBase: g.isBase);
        _changed = true;
      });
    }
  }

  Future<void> _confirmDelete(Group g) async {
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
    if (ok != true) return;
    final token = await ApiService.getToken();
    if (token == null) return;
    final response = await ApiService.deleteGroup(token, g.id);
    if (response.statusCode == 200 && mounted) {
      setState(() {
        _groups.removeWhere((e) => e.id == g.id);
        _changed = true;
      });
    }
  }

  Future<void> _addDraft() async {
    final token = await ApiService.getToken();
    if (token == null) return;
    final response = await ApiService.createGroup(token, 'Новая группа');
    if (response.statusCode != 200 || !mounted) return;
    final group = Group.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    setState(() {
      _groups.add(group);
      _changed = true;
    });
    _startEdit(group);
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final reorderable = _groups.where((g) => !g.isBase).toList();
      final item = reorderable.removeAt(oldIndex);
      reorderable.insert(newIndex, item);
      final base = _groups.where((g) => g.isBase).toList();
      _groups = [...base, ...reorderable];
      _changed = true;
    });
    final token = await ApiService.getToken();
    if (token == null) return;
    final ids = _groups.where((g) => !g.isBase).map((g) => g.id).toList();
    await ApiService.reorderGroups(token, ids);
  }

  @override
  Widget build(BuildContext context) {
    final baseGroups = _filtered.where((g) => g.isBase).toList();
    final reorderableGroups = _filtered.where((g) => !g.isBase).toList();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 31, 31, 31),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(_changed),
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
          if (_loading)
            const Expanded(child: Center(child: LoadingIndicator()))
          else if (_error != null)
            Expanded(child: Center(child: Text('Ошибка: $_error', style: const TextStyle(color: Colors.white))))
          else ...[
              for (final g in baseGroups)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: _GroupCard(group: g, isBase: true),
                ),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: reorderableGroups.length,
                  onReorder: _reorder,
                  itemBuilder: (context, index) {
                    final g = reorderableGroups[index];
                    final editing = _editingGroupId == g.id;
                    return _GroupCard(
                      key: ValueKey(g.id),
                      index: index,
                      group: g,
                      isBase: false,
                      editing: editing,
                      controller: _editControllers[g.id],
                      onEdit: () => _startEdit(g),
                      onConfirm: () => _confirmEdit(g),
                      onDelete: () => _confirmDelete(g),
                    );
                  },
                ),
              ),
            ],
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

class _GroupCard extends StatelessWidget {
  final int index;
  final Group group;
  final bool isBase;
  final bool editing;
  final TextEditingController? controller;
  final VoidCallback? onEdit;
  final VoidCallback? onConfirm;
  final VoidCallback? onDelete;

  const _GroupCard({
    super.key,
    this.index = 0,
    required this.group,
    required this.isBase,
    this.editing = false,
    this.controller,
    this.onEdit,
    this.onConfirm,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(color: const Color.fromARGB(255, 40, 40, 40), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: isBase
                ? const Icon(Icons.lock, color: Colors.white54)
                : ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle, color: Colors.white54),
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
          if (!isBase) ...[
            IconButton(
              icon: Icon(editing ? Icons.check : Icons.edit, color: editing ? Colors.green : Colors.white70),
              onPressed: editing ? onConfirm : onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white70),
              onPressed: onDelete,
            ),
          ],
        ]),
      ),
    );
  }
}