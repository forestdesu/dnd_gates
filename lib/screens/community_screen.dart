import 'package:flutter/material.dart';
import '../item_detail.dart';
import '../services/api_service.dart';
import 'dart:convert';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

// Модель для товара
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

// Функция для загрузки lookups (редкости, типы, свойства)
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
      return {
        'rarities': rar,
        'types': types,
        'properties': props,
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

// Функция для загрузки товаров с API (пагинация)
Future<Map<String, dynamic>> fetchItemsPage(
    int page, {
      int pageSize = 30,
      List<int>? rarityIds,
      int? itemTypeId,
      List<int>? specialTypeIds,
      int? priceMin,
      int? priceMax,
    }) async {
  try {
    final queryAll = <String, List<String>>{};
    queryAll['page'] = [page.toString()];
    queryAll['page_size'] = [pageSize.toString()];
    if (rarityIds != null && rarityIds.isNotEmpty) queryAll['rarity_id'] = rarityIds.map((e) => e.toString()).toList();
    if (itemTypeId != null) queryAll['item_type_id'] = [itemTypeId.toString()];
    if (specialTypeIds != null && specialTypeIds.isNotEmpty) queryAll['special_type_id'] = specialTypeIds.map((e) => e.toString()).toList();
    if (priceMin != null) queryAll['price_min'] = [priceMin.toString()];
    if (priceMax != null) queryAll['price_max'] = [priceMax.toString()];

    // Build the query string manually (supports repeated keys)
    final parts = <String>[];
    queryAll.forEach((k, list) {
      for (final v in list) {
        parts.add('${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}');
      }
    });
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
      int? itemTypeId,
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
    if (itemTypeId != null) queryAll['item_type_id'] = [itemTypeId.toString()];
    if (specialTypeIds != null && specialTypeIds.isNotEmpty) queryAll['special_type_id'] = specialTypeIds.map((e) => e.toString()).toList();
    if (priceMin != null) queryAll['price_min'] = [priceMin.toString()];
    if (priceMax != null) queryAll['price_max'] = [priceMax.toString()];

    final parts = <String>[];
    queryAll.forEach((k, list) {
      for (final v in list) {
        parts.add('${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}');
      }
    });
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
  final TextEditingController _searchController = TextEditingController();

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
  String? _filterType;
  final Set<String> _filterRarities = <String>{};
  final TextEditingController _priceFromController = TextEditingController();
  final TextEditingController _priceToController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadItems();
    _loadLookups();
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
      if (!_isLoading && _currentPage < _totalPages) {
        _loadMoreItems();
      }
    }
  }

  Future<void> _loadLookups() async {
    final needLocalFilter = (_lookupProperties.isEmpty && _filterProperties.isNotEmpty) ||
        (_lookupTypes.isEmpty && _filterType != null && _filterType != 'Любой') ||
        (_lookupRarities.isEmpty && _filterRarities.isNotEmpty);
    if (needLocalFilter) {
      final bool useFrom = _priceFromController.text.isNotEmpty && int.tryParse(_priceFromController.text) != null;
      final bool useTo = _priceToController.text.isNotEmpty && int.tryParse(_priceToController.text) != null;
      final filtered = _itemsOriginal.where((item) {
        if (_filterProperties.isNotEmpty) {
          final has = item.specialTypes.any((s) => _filterProperties.contains(s));
          if (!has) return false;
        }
        if (_filterType != null && _filterType != 'Любой') {
          if (!item.types.contains(_filterType)) return false;
        }
        if (_filterRarities.isNotEmpty) {
          if (!_filterRarities.contains(item.rarity)) return false;
        }
        if (useFrom && item.price < (int.tryParse(_priceFromController.text) ?? 0)) return false;
        if (useTo && item.price > (int.tryParse(_priceToController.text) ?? 0)) return false;
        return true;
      }).toList();
      setState(() {
        _items = filtered;
        _isLoading = false;
      });
      return;
    }
    try {
      final lookupsData = await fetchLookups();
      if (!mounted) return;
      setState(() {
        _lookupRarities = lookupsData['rarities'] ?? [];
        _lookupTypes = lookupsData['types'] ?? [];
        _lookupProperties = lookupsData['properties'] ?? [];
      });
    } catch (e) {
      // ignore lookups loading errors silently
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
          if (found.isNotEmpty && found['id'] != null) {
            ids.add(found['id'] as int);
          }
        }
        if (ids.isNotEmpty) rarityIds = ids;
      }
      int? itemTypeId;
      if (_filterType != null && _filterType != 'Любой') {
        final found = _lookupTypes.firstWhere((m) => m['name'] == _filterType, orElse: () => {});
        if (found.isNotEmpty && found['id'] != null) itemTypeId = found['id'] as int;
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
            page: page,
            pageSize: 30,
            rarityIds: rarityIds,
            itemTypeId: itemTypeId,
            specialTypeIds: specialTypeIds,
            priceMin: priceMin,
            priceMax: priceMax);
      } else {
        data = await fetchItemsPage(page,
            pageSize: 30,
            rarityIds: rarityIds,
            itemTypeId: itemTypeId,
            specialTypeIds: specialTypeIds,
            priceMin: priceMin,
            priceMax: priceMax);
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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 31, 31, 31),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
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
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ]),
                const Divider(color: Colors.white12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Свойства', style: headerStyle),
                  trailing: Text(_filterProperties.isEmpty ? 'Любые >' : '${_filterProperties.length} выбрано', style: const TextStyle(color: Colors.white70)),
                  onTap: () async {
                    final selected = await showDialog<Set<String>>(
                      context: context,
                      builder: (dctx) {
                        final temp = Set<String>.from(_filterProperties);
                        return StatefulBuilder(
                          builder: (ctx, setStateDialog) {
                            return AlertDialog(
                              backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
                              title: const Text('Свойства', style: TextStyle(color: Colors.white)),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: props.map((p) {
                                    return CheckboxListTile(
                                      value: temp.contains(p),
                                      title: Text(p, style: const TextStyle(color: Colors.white)),
                                      onChanged: (v) {
                                        setStateDialog(() {
                                          if (v == true) {
                                            temp.add(p);
                                          } else {
                                            temp.remove(p);
                                          }
                                        });
                                      },
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
                          },
                        );
                      },
                    );
                    if (selected != null) {
                      setState(() {
                        _filterProperties
                          ..clear()
                          ..addAll(selected);
                      });
                      setStateSheet(() {});
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Тип', style: headerStyle),
                  trailing: Text(_filterType ?? 'Любой >', style: const TextStyle(color: Colors.white70)),
                  onTap: () async {
                    final options = <String>['Любой'] + types.toList();
                    final selected = await showDialog<String?>(
                      context: context,
                      builder: (dctx) {
                        return SimpleDialog(
                          backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
                          title: const Text('Тип', style: TextStyle(color: Colors.white)),
                          children: options.map((option) {
                            return SimpleDialogOption(
                              onPressed: () => Navigator.of(dctx).pop(option == 'Любой' ? null : option),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: option,
                                    groupValue: _filterType ?? 'Любой',
                                    onChanged: (_) => Navigator.of(dctx).pop(option == 'Любой' ? null : option),
                                  ),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    );
                    if (selected != _filterType) {
                      setState(() {
                        _filterType = selected;
                      });
                      setStateSheet(() {});
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Редкость', style: headerStyle),
                  trailing: Text(_filterRarities.isEmpty ? 'Любая >' : '${_filterRarities.length} выбрано', style: const TextStyle(color: Colors.white70)),
                  onTap: () async {
                    final selected = await showDialog<Set<String>>(
                      context: context,
                      builder: (dctx) {
                        final temp = Set<String>.from(_filterRarities);
                        return StatefulBuilder(
                          builder: (ctx, setStateDialog) {
                            return AlertDialog(
                              backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
                              title: const Text('Редкость', style: TextStyle(color: Colors.white)),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: rarities.map((r) {
                                    return CheckboxListTile(
                                      value: temp.contains(r),
                                      title: Text(r, style: const TextStyle(color: Colors.white)),
                                      onChanged: (v) {
                                        setStateDialog(() {
                                          if (v == true) {
                                            temp.add(r);
                                          } else {
                                            temp.remove(r);
                                          }
                                        });
                                      },
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
                          },
                        );
                      },
                    );
                    if (selected != null) {
                      setState(() {
                        _filterRarities
                          ..clear()
                          ..addAll(selected);
                      });
                      setStateSheet(() {});
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text('Цена (мед.)', style: headerStyle),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: TextField(
                        controller: _priceFromController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'От',
                          hintStyle: const TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(132,132,137,1.0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(132,132,137,1.0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(132,132,137,1.0))),
                          filled: false,
                        ),
                      )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                        controller: _priceToController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'До',
                          hintStyle: const TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(132,132,137,1.0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(132,132,137,1.0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(132,132,137,1.0))),
                          filled: false,
                        ),
                      )),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextButton(
                        style: TextButton.styleFrom(backgroundColor: Colors.transparent, side: const BorderSide(color: Colors.white12)),
                        onPressed: () {
                          setState(() {
                            _filterProperties.clear();
                            _filterType = null;
                            _filterRarities.clear();
                            _priceFromController.clear();
                            _priceToController.clear();
                          });
                          _applyFilters();
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
                          _applyFilters();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Применить'),
                      ),
                    ),
                  ),
                ])
              ]),
            );
          }),
        );
      },
    );
  }

  String _formatPrice(int price) {
    if (price <= 0) return 'Бесплатно';
    if (price % 100 == 0) {
      final g = price ~/ 100;
      return '$g зол.';
    } else if (price % 10 == 0) {
      final s = price ~/ 10;
      return '$s серебр.';
    } else {
      return '$price мед.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
        Expanded(
          child: _error != null && _items.isEmpty
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
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final item = _items[i];
              final imageUrl = item.icon ?? 'https://poe2-biblioteka.ru/Predmeti/Battlestaves/warstaff_2.webp';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemDetailPage(itemId: item.id, initialName: item.name, initialImageUrl: imageUrl),
                      ),
                    );
                  },
                  child: Card(
                    color: const Color.fromARGB(255, 40, 40, 40),
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 80,
                              height: 200,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.fill,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.name,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Редкость: ${item.rarity}',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Тип: ${item.types.isNotEmpty ? item.types.join(", ") : "Не определен"}',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  if (item.specialTypes.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text('Свойства:', style: theme.textTheme.labelSmall),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: item.specialTypes
                                          .map((s) => Chip(
                                        label: Text(s, style: const TextStyle(color: Colors.white)),
                                        backgroundColor: Colors.grey[800],
                                      ))
                                          .toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    'Цена: ${_formatPrice(item.price)}',
                                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.amber),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}