import 'package:flutter/material.dart';
import '../widgets/item_image.dart';
import 'community.dart' show Item;

class ShopScreen extends StatefulWidget {
  final List<Item> items;
  final bool isLoading;
  final String? error;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final VoidCallback onFiltersOpen;
  final Function(Item) onItemTap;
  final String Function(int) formatPrice;

  const ShopScreen({
    required this.items,
    required this.isLoading,
    required this.error,
    required this.scrollController,
    required this.searchController,
    required this.onSearch,
    required this.onFiltersOpen,
    required this.onItemTap,
    required this.formatPrice,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextField(
            controller: widget.searchController,
            onChanged: (_) => widget.onSearch(),
            decoration: InputDecoration(
              hintText: 'Поиск предметов...',
              hintStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: const Color.fromRGBO(37, 37, 39, 1.0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon: widget.searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        widget.searchController.clear();
                        widget.onSearch();
                      },
                    )
                  : null,
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              iconSize: 28,
              icon: const Icon(Icons.filter_list),
              color: Colors.white,
              onPressed: widget.onFiltersOpen,
              tooltip: 'Фильтры',
            ),
          ),
        ],
      ),
      body: widget.error != null && widget.items.isEmpty
          ? Center(
              child: Text(
                'Ошибка: ${widget.error}',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          : widget.items.isEmpty && !widget.isLoading
              ? const Center(child: Text('Нет данных', style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  controller: widget.scrollController,
                  itemCount: widget.items.length + (widget.isLoading ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == widget.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final item = widget.items[i];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: InkWell(
                        onTap: () => widget.onItemTap(item),
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
                                    child: ItemImage(url: item.icon, fit: BoxFit.fill),
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
                                          'Цена: ${widget.formatPrice(item.price)}',
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
    );
  }
}



