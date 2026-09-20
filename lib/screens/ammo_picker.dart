import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'community.dart' show Item, fetchItemsPage, fetchItemsSearch;
import '../controllers/lookups.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/filters_sheet.dart';

class AmmoPickerScreen extends StatefulWidget {
  final List<Item> initialSelected; // было: Set<int> initialSelectedIds
  const AmmoPickerScreen({super.key, this.initialSelected = const []});

  @override
  State<AmmoPickerScreen> createState() => _AmmoPickerScreenState();
}

class _AmmoPickerScreenState extends State<AmmoPickerScreen> {
  late ScrollController _scrollController;
  List<Map<String, dynamic>> _lookupProperties = [];
  List<Map<String, dynamic>> _lookupRarities = [];
  final Set<String> _filterProperties = <String>{};
  final Set<String> _filterRarities = <String>{};
  final TextEditingController _priceFromController = TextEditingController();
  final TextEditingController _priceToController = TextEditingController();


  final TextEditingController _searchController = TextEditingController();

  List<Item> _items = [];
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  int? _ammoTypeId;
  final Map<int, Item> _selected = {}; // id -> Item, чтобы вернуть полные объекты

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    final lookups = context.read<LookupsController>();
    final types = context.read<LookupsController>().types;
    final ammoType = types.firstWhere((t) => t['name'] == 'Боеприпасы', orElse: () => {});
    _ammoTypeId = ammoType['id'] as int?;
    _lookupRarities = lookups.rarities;
    _lookupProperties = lookups.properties;
    for (final item in widget.initialSelected) {
      _selected[item.id] = item;
    }
    _loadItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _priceFromController.dispose();
    _priceToController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      if (!_isLoading && _currentPage < _totalPages) _loadMore();
    }
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _items = [];
    });
    await _fetch(page: 1, append: false);
  }

  Future<void> _loadMore() async {
    if (_isLoading || _currentPage >= _totalPages) return;
    await _fetch(page: _currentPage + 1, append: true);
  }

  Future<void> _fetch({required int page, required bool append}) async {
    setState(() => _isLoading = true);
    try {
      List<int>? rarityIds;
      if (_filterRarities.isNotEmpty) {
        final ids = <int>[];
        for (final name in _filterRarities) {
          final found = _lookupRarities.firstWhere((m) => m['name'] == name, orElse: () => {});
          if (found.isNotEmpty && found['id'] != null) ids.add(found['id'] as int);
        }
        if (ids.isNotEmpty) rarityIds = ids;
      }
      List<int>? specialTypeIds;
      if (_filterProperties.isNotEmpty) {
        final ids = <int>[];
        for (final name in _filterProperties) {
          final f = _lookupProperties.firstWhere((m) => m['name'] == name, orElse: () => {});
          if (f.isNotEmpty && f['id'] != null) ids.add(f['id'] as int);
        }
        if (ids.isNotEmpty) specialTypeIds = ids;
      }
      final priceMin = int.tryParse(_priceFromController.text);
      final priceMax = int.tryParse(_priceToController.text);

      final query = _isSearching ? _searchController.text : null;
      final data = (query != null && query.isNotEmpty)
          ? await fetchItemsSearch(query, page: page, pageSize: 30, itemTypeIds: _ammoTypeId != null ? [_ammoTypeId!] : null, rarityIds: rarityIds, specialTypeIds: specialTypeIds, priceMin: priceMin, priceMax: priceMax)
          : await fetchItemsPage(page, pageSize: 30, itemTypeIds: _ammoTypeId != null ? [_ammoTypeId!] : null, rarityIds: rarityIds, specialTypeIds: specialTypeIds, priceMin: priceMin, priceMax: priceMax);
      final fetched = (data['items'] as List<Item>?) ?? [];
      if (!mounted) return;
      setState(() {
        if (append) { _items.addAll(fetched); } else { _items = fetched; }
        _currentPage = data['page'] as int? ?? page;
        _totalPages = data['total_pages'] as int? ?? _totalPages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _search(String q) {
    _isSearching = q.isNotEmpty;
    _loadItems();
  }

  void _toggle(Item item) {
    setState(() {
      if (_selected.containsKey(item.id)) { _selected.remove(item.id); } else { _selected[item.id] = item; }
    });
  }

  Future<void> _openFilters() async {
    final props = Set<String>.from(_lookupProperties.map((e) => e['name'] as String));
    final rarities = Set<String>.from(_lookupRarities.map((e) => e['name'] as String));

    await showFiltersSheet(
      context,
      multiSelectFilters: [
        MultiSelectFilter(label: 'Свойства', options: props, selected: _filterProperties),
        MultiSelectFilter(label: 'Редкость', options: rarities, selected: _filterRarities),
      ],
      priceLabel: 'Цена (мед.)',
      priceFromController: _priceFromController,
      priceToController: _priceToController,
      onReset: () {
        setState(() {
          _filterProperties.clear();
          _filterRarities.clear();
          _priceFromController.clear();
          _priceToController.clear();
        });
        _loadItems();
      },
      onApply: _loadItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 31, 31, 31),
      appBar: AppBar(title: const Text('Выбор боеприпасов'), backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0)),
      body: Column(children: [
        Container(
          color: const Color.fromRGBO(37, 37, 39, 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _search,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Поиск боеприпасов...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: const Color.fromRGBO(45, 45, 47, 1.0),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                ),
              ),
            ),
            IconButton(iconSize: 28, icon: const Icon(Icons.filter_list), color: Colors.white, onPressed: _openFilters, tooltip: 'Фильтры'), // восстановлено
            if (_selected.isNotEmpty) // было > 1, теперь isNotEmpty
              IconButton(iconSize: 26, icon: const Icon(Icons.clear_all), color: Colors.white70, onPressed: () => setState(_selected.clear), tooltip: 'Сбросить выбор'),
          ]),
        ),
        Expanded(
          child: _error != null && _items.isEmpty
              ? Center(child: Text('Ошибка: $_error', style: theme.textTheme.bodyMedium))
              : _items.isEmpty && !_isLoading
              ? const Center(child: Text('Нет данных', style: TextStyle(color: Colors.white)))
              : ListView.builder(
            controller: _scrollController,
            itemCount: _items.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == _items.length) {
                return const Padding(padding: EdgeInsets.all(16), child: Center(child: LoadingIndicator(size: 60)));
              }
              final item = _items[i];
              final imageUrl = item.icon ?? 'https://poe2-biblioteka.ru/Predmeti/Battlestaves/warstaff_2.webp';
              final isSelected = _selected.containsKey(item.id);
              return InkWell(
                onTap: () => _toggle(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Card(
                    color: const Color.fromARGB(255, 40, 40, 40),
                    clipBehavior: Clip.antiAlias,
                    child: Row(children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? Colors.red : Colors.white38,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ),
                      Expanded(
                        child: Text(item.name, style: theme.textTheme.bodyMedium),
                      ),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
        if (_selected.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selected.values.toList()),
                  child: Text('Выбрать ${_selected.length} боеприпасов'),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}