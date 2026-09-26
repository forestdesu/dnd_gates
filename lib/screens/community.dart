import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'item_detail.dart';
import '../services/api_service.dart';
import '../controllers/lookups.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/item_card.dart';
import '../widgets/tab_switcher.dart';
import 'dart:convert';
import 'create_item_screen.dart';
import '../controllers/items_update_notifier.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class Item {
  final int id;
  final String name;
  final String? icon;
  final String rarity;
  final int price;
  final List<String> types;
  final List<String> specialTypes;

  Item({
    required this.id,
    required this.name,
    required this.icon,
    required this.rarity,
    required this.price,
    required this.types,
    required this.specialTypes,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Неизвестный товар',
      icon: json['icon'] as String?,
      rarity: json['rarity'] as String? ?? 'Не имеет редкости',
      price: json['price'] as int? ?? 0,
      types: List<String>.from(json['types'] as List<dynamic>? ?? []),
      specialTypes: List<String>.from(json['special_types'] as List<dynamic>? ?? []),
    );
  }
}

class MyItem {
  final int id;
  final String name;
  final String? icon;
  final String rarity;
  final int price;
  final int status;

  MyItem({required this.id, required this.name, required this.icon, required this.rarity, required this.price, required this.status});

  factory MyItem.fromJson(Map<String, dynamic> json) {
    return MyItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Неизвестный предмет',
      icon: json['icon'] as String?,
      rarity: json['rarity'] as String? ?? 'Не имеет редкости',
      price: json['price'] as int? ?? 0,
      status: json['status'] as int? ?? 0,
    );
  }
}

const Map<int, Color> statusColors = {
  3: Colors.red,
  2: Colors.green,
  1: Colors.orange,
  0: Colors.lightBlue,
};
const Map<int, String> statusLabels = {
  3: 'Удалён',
  2: 'Опубликован',
  1: 'На рассмотрении',
  0: 'Создан',
};

Future<Map<String, dynamic>> fetchMyItemsPage(String token, int page, {int pageSize = 30}) async {
  try {
    final response = await ApiService.getMyItems(token, page, pageSize);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>?)
          ?.map((item) => MyItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [];
      return {
        'items': items,
        'page': data['page'] as int? ?? page,
        'total_pages': data['total_pages'] as int? ?? 0,
      };
    } else {
      throw Exception('Ошибка загрузки данных: ${response.statusCode}');
    }
  } on Exception {
    rethrow;
  } catch (e) {
    throw Exception('Ошибка подключения: $e');
  }
}

Future<Map<String, List<Map<String, dynamic>>>> fetchLookups() async {
  try {
    final resp = await ApiService.getLookups();
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final rar = (data['rarities'] as List<dynamic>?)
          ?.map((e) {
        final m = e as Map<String, dynamic>;
        return <String, dynamic>{'id': m['id'], 'name': m['name']};
      }).toList() ?? [];
      final types = (data['item_types'] as List<dynamic>?)
          ?.map((e) {
        final m = e as Map<String, dynamic>;
        return <String, dynamic>{'id': m['id'], 'name': m['name']};
      }).toList() ?? [];
      final props = (data['special_types'] as List<dynamic>?)
          ?.map((e) {
        final m = e as Map<String, dynamic>;
        return <String, dynamic>{'id': m['id'], 'name': m['name']};
      }).toList() ?? [];
      final damageTypes = (data['damage_types'] as List<dynamic>?)
          ?.map((e) {
        final m = e as Map<String, dynamic>;
        return <String, dynamic>{'id': m['id'], 'name': m['name']};
      }).toList() ?? [];
      final dice = (data['dice'] as List<dynamic>?)
          ?.map((e) {
        final m = e as Map<String, dynamic>;
        return <String, dynamic>{'id': m['id'], 'name': m['name'], 'sides': m['sides']};
      }).toList() ?? [];
      return {
        'rarities': rar,
        'types': types,
        'properties': props,
        'damageTypes': damageTypes,
        'dice': dice,
      };
    } else {
      throw Exception('Ошибка загрузки lookups: ${resp.statusCode}');
    }
  } on Exception {
    rethrow;
  } catch (e) {
    throw Exception('Ошибка подключения при загрузке lookups: $e');
  }
}

Future<Map<String, dynamic>> fetchItemsPage(
    int page, {
      int pageSize = 30,
      List<int>? rarityIds,
      List<int>? itemTypeIds,
      List<int>? specialTypeIds,
      int? priceMin,
      int? priceMax,
    }) async {
  try {
    final queryAll = <String, List<String>>{};
    queryAll['page'] = [page.toString()];
    queryAll['page_size'] = [pageSize.toString()];
    if (rarityIds != null && rarityIds.isNotEmpty) queryAll['rarity_id'] = rarityIds.map((e) => e.toString()).toList();
    if (itemTypeIds != null && itemTypeIds.isNotEmpty) queryAll['item_type_id'] = itemTypeIds.map((e) => e.toString()).toList();
    if (specialTypeIds != null && specialTypeIds.isNotEmpty) queryAll['special_type_id'] = specialTypeIds.map((e) => e.toString()).toList();
    if (priceMin != null) queryAll['price_min'] = [priceMin.toString()];
    if (priceMax != null) queryAll['price_max'] = [priceMax.toString()];


    final response = await ApiService.getItems(queryAll);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>?)
          ?.map((item) => Item.fromJson(item as Map<String, dynamic>))
          .toList() ?? [];
      return {
        'items': items,
        'page': data['page'] as int? ?? page,
        'page_size': data['page_size'] as int? ?? pageSize,
        'total_count': data['total_count'] as int? ?? 0,
        'total_pages': data['total_pages'] as int? ?? 0,
      };
    } else {
      throw Exception('Ошибка загрузки данных: ${response.statusCode}');
    }
  } on Exception {
    rethrow;
  } catch (e) {
    throw Exception('Ошибка подключения: $e');
  }
}

Future<Map<String, dynamic>> fetchItemsSearch(
    String query, {
      int page = 1,
      int pageSize = 30,
      List<int>? rarityIds,
      List<int>? itemTypeIds,
      List<int>? specialTypeIds,
      int? priceMin,
      int? priceMax,
    }) async {
  try {
    final queryAll = <String, List<String>>{};
    queryAll['q'] = [query];
    queryAll['page'] = [page.toString()];
    queryAll['page_size'] = [pageSize.toString()];
    if (rarityIds != null && rarityIds.isNotEmpty) queryAll['rarity_id'] = rarityIds.map((e) => e.toString()).toList();
    if (itemTypeIds != null && itemTypeIds.isNotEmpty) queryAll['item_type_id'] = itemTypeIds.map((e) => e.toString()).toList();
    if (specialTypeIds != null && specialTypeIds.isNotEmpty) queryAll['special_type_id'] = specialTypeIds.map((e) => e.toString()).toList();
    if (priceMin != null) queryAll['price_min'] = [priceMin.toString()];
    if (priceMax != null) queryAll['price_max'] = [priceMax.toString()];

    final response = await ApiService.getItemsSearch(queryAll);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>?)
          ?.map((item) => Item.fromJson(item as Map<String, dynamic>))
          .toList() ?? [];
      return {
        'items': items,
        'page': data['page'] as int? ?? page,
        'page_size': data['page_size'] as int? ?? pageSize,
        'total_count': data['total_count'] as int? ?? 0,
        'total_pages': data['total_pages'] as int? ?? 0,
      };
    } else {
      throw Exception('Ошибка загрузки данных: ${response.statusCode}');
    }
  } on Exception {
    rethrow;
  } catch (e) {
    throw Exception('Ошибка подключения: $e');
  }
}


class _CommunityScreenState extends State<CommunityScreen> {
  late ScrollController _scrollController;
  late final ItemsUpdateNotifier _itemsUpdateNotifier;
  final TextEditingController _searchController = TextEditingController();

  int _tab = 0;
  late ScrollController _myScrollController;
  List<MyItem> _myItems = [];
  int _myCurrentPage = 1;
  int _myTotalPages = 0;
  bool _myIsLoading = false;
  String? _myError;

  List<Item> _items = [];
  List<Item> _itemsOriginal = [];
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  List<Map<String, dynamic>> _lookupProperties = [];
  List<Map<String, dynamic>> _lookupTypes = [];
  List<Map<String, dynamic>> _lookupRarities = [];

  final Set<String> _filterProperties = <String>{};
  final Set<String> _filterTypes = <String>{};
  final Set<String> _filterRarities = <String>{};
  final TextEditingController _priceFromController = TextEditingController();
  final TextEditingController _priceToController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadItems();
    final lookups = context.read<LookupsController>();
    _lookupRarities = lookups.rarities;
    _lookupTypes = lookups.types;
    _lookupProperties = lookups.properties;
    _myScrollController = ScrollController()..addListener(_onMyScroll);
    _itemsUpdateNotifier = context.read<ItemsUpdateNotifier>();
    _itemsUpdateNotifier.addListener(_onItemsChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _priceFromController.dispose();
    _priceToController.dispose();
    _myScrollController.dispose();
    _itemsUpdateNotifier.removeListener(_onItemsChanged);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      if (!_isLoading && _currentPage < _totalPages) {
        _loadMoreItems();
      }
    }
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _items = [];
      _itemsOriginal = [];
    });
    await _applyFilters(searchQuery: _isSearching ? _searchController.text : null, page: 1, append: false);
  }

  void _onItemsChanged() {
    _loadItems();
    if (_tab == 1) _loadMyItems();
  }

  void _onMyScroll() {
    if (_myScrollController.position.pixels >= _myScrollController.position.maxScrollExtent - 500) {
      if (!_myIsLoading && _myCurrentPage < _myTotalPages) {
        _loadMoreMyItems();
      }
    }
  }

  void _handleDetailResult(dynamic result) { // НОВОЕ
    if (result is Map && result['filterSpecialType'] != null) {
      final name = result['filterSpecialType'] as String;
      setState(() {
        _tab = 0;
        _filterTypes.clear();
        _filterRarities.clear();
        _priceFromController.clear();
        _priceToController.clear();
        _filterProperties
          ..clear()
          ..add(name);
      });
      _applyFilters();
    }
  }

  Future<void> _loadMyItems() async {
    final token = await ApiService.getToken();
    if (token == null) {
      setState(() => _myError = 'Необходимо войти в аккаунт');
      return;
    }
    setState(() {
      _myIsLoading = true;
      _myError = null;
      _myCurrentPage = 1;
      _myItems = [];
    });
    try {
      final data = await fetchMyItemsPage(token, 1);
      if (!mounted) return;
      setState(() {
        _myItems = (data['items'] as List<MyItem>?) ?? [];
        _myCurrentPage = data['page'] as int? ?? 1;
        _myTotalPages = data['total_pages'] as int? ?? 0;
        _myIsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _myError = e.toString();
        _myIsLoading = false;
      });
    }
  }

  Future<void> _loadMoreMyItems() async {
    final token = await ApiService.getToken();
    if (token == null || _myIsLoading || _myCurrentPage >= _myTotalPages) return;
    setState(() => _myIsLoading = true);
    try {
      final data = await fetchMyItemsPage(token, _myCurrentPage + 1);
      if (!mounted) return;
      setState(() {
        _myItems.addAll((data['items'] as List<MyItem>?) ?? []);
        _myCurrentPage = data['page'] as int? ?? _myCurrentPage;
        _myTotalPages = data['total_pages'] as int? ?? _myTotalPages;
        _myIsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _myIsLoading = false);
    }
  }

  Future<void> _openCreateItem() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateItemScreen()),
    );
  }

  void _switchTab(int tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    if (tab == 1 && _myItems.isEmpty && !_myIsLoading) _loadMyItems();
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading || _currentPage >= _totalPages) return;
    final nextPage = _currentPage + 1;
    await _applyFilters(searchQuery: _isSearching ? _searchController.text : null, page: nextPage, append: true);
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      _isSearching = false;
      await _loadItems();
      return;
    }
    _isSearching = true;
    await _applyFilters(searchQuery: query, page: 1, append: false);
  }

  Future<void> _applyFilters({String? searchQuery, int page = 1, bool append = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
      List<int>? itemTypeIds;
      if (_filterTypes.isNotEmpty) {
        final ids = <int>[];
        for (final name in _filterTypes) {
          final found = _lookupTypes.firstWhere((m) => m['name'] == name, orElse: () => {});
          if (found.isNotEmpty && found['id'] != null) ids.add(found['id'] as int);
        }
        if (ids.isNotEmpty) itemTypeIds = ids;
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

      Map<String, dynamic> data;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        data = await fetchItemsSearch(searchQuery,
            page: page, pageSize: 30,
            rarityIds: rarityIds, itemTypeIds: itemTypeIds, specialTypeIds: specialTypeIds,
            priceMin: priceMin, priceMax: priceMax);
      } else {
        data = await fetchItemsPage(page,
            pageSize: 30,
            rarityIds: rarityIds, itemTypeIds: itemTypeIds, specialTypeIds: specialTypeIds,
            priceMin: priceMin, priceMax: priceMax);
      }

      final fetched = (data['items'] as List<Item>?) ?? [];
      if (!mounted) return;
      setState(() {
        if (append) {
          _itemsOriginal.addAll(fetched);
          _items.addAll(fetched);
          _currentPage = data['page'] as int? ?? page;
          _totalPages = data['total_pages'] as int? ?? _totalPages;
        } else {
          _itemsOriginal = fetched;
          _items = fetched;
          _currentPage = data['page'] as int? ?? page;
          _totalPages = data['total_pages'] as int? ?? 0;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openFilters() async {
    final props = _lookupProperties.isNotEmpty
        ? Set<String>.from(_lookupProperties.map((e) => e['name'] as String))
        : <String>{}..addAll(_itemsOriginal.expand((it) => it.specialTypes));
    final types = _lookupTypes.isNotEmpty
        ? Set<String>.from(_lookupTypes.map((e) => e['name'] as String))
        : <String>{}..addAll(_itemsOriginal.expand((it) => it.types));
    final rarities = _lookupRarities.isNotEmpty
        ? Set<String>.from(_lookupRarities.map((e) => e['name'] as String))
        : <String>{}..addAll(_itemsOriginal.map((it) => it.rarity));

    await showFiltersSheet(
      context,
      multiSelectFilters: [
        MultiSelectFilter(label: 'Тип', options: types, selected: _filterTypes),
        MultiSelectFilter(label: 'Свойства', options: props, selected: _filterProperties),
        MultiSelectFilter(label: 'Редкость', options: rarities, selected: _filterRarities),
      ],
      priceLabel: 'Цена (мед.)',
      priceFromController: _priceFromController,
      priceToController: _priceToController,
      onReset: () {
        setState(() {
          _filterProperties.clear();
          _filterTypes.clear();
          _filterRarities.clear();
          _priceFromController.clear();
          _priceToController.clear();
        });
        _applyFilters();
      },
      onApply: _applyFilters,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Column(
          children: [
            Container(
              color: const Color.fromRGBO(37, 37, 39, 1.0),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _search,
                      decoration: InputDecoration(
                        hintText: 'Поиск предметов...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: const Color.fromRGBO(45, 45, 47, 1.0),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                            _search('');
                          },
                        )
                            : null,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    iconSize: 28,
                    icon: const Icon(Icons.filter_list),
                    color: Colors.white,
                    onPressed: _openFilters,
                    tooltip: 'Фильтры',
                  ),
                ],
              ),
            ),
            TabSwitcher(
              labels: const ['Публичные работы', 'Мои работы'],
              selectedIndex: _tab,
              onTap: _switchTab,
            ),
            Expanded(
              child: _tab == 0 ? _buildPublicList(theme) : _buildMyList(theme),
            ),
          ],
        ),
        if (_tab == 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _openCreateItem,
              backgroundColor: Colors.red,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  Widget _buildPublicList(ThemeData theme) {
    return _error != null && _items.isEmpty
        ? Center(
      child: Text(
        'Ошибка: $_error',
        style: theme.textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    )
        : _items.isEmpty && !_isLoading
        ? const Center(child: Text('Нет данных', style: TextStyle(color: Colors.white)))
        : ListView.builder(
      controller: _scrollController,
      itemCount: _items.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: LoadingIndicator(size: 60)),
          );
        }

        final item = _items[i];

        return PublicItemCard(
          item: item,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailPage(
                  itemId: item.id,
                  initialName: item.name,
                  initialImageUrl: item.icon,
                ),
              ),
            );
            _handleDetailResult(result);
          },
        );
      },
    );
  }

  Widget _buildMyList(ThemeData theme) {
    if (_myError != null && _myItems.isEmpty) {
      return Center(child: Text('Ошибка: $_myError', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center));
    }
    if (_myItems.isEmpty && !_myIsLoading) {
      return const Center(child: Text('У вас пока нет работ', style: TextStyle(color: Colors.white)));
    }
    return ListView.builder(
      controller: _myScrollController,
      itemCount: _myItems.length + (_myIsLoading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _myItems.length) {
          return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: LoadingIndicator(size: 60)));
        }
        final item = _myItems[i];
        return MyItemCard(
          item: item,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailPage(
                  itemId: item.id,
                  initialName: item.name,
                  initialImageUrl: item.icon,
                ),
              ),
            );
            _handleDetailResult(result);
          },
        );
      },
    );
  }
}