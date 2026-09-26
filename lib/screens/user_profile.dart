import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/items_update_notifier.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/item_card.dart' show MyItemCard;
import 'community.dart' show MyItem;
import 'item_detail.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final ItemsUpdateNotifier _itemsUpdateNotifier;
  static const _textStyle = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500);

  Map<String, dynamic>? _user;
  List<MyItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _itemsUpdateNotifier = context.read<ItemsUpdateNotifier>();
    _itemsUpdateNotifier.addListener(_load);
  }

  @override
  void dispose() {
    _itemsUpdateNotifier.removeListener(_load);
    super.dispose();
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService.getUserProfile(widget.userId);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _user = data['user'] as Map<String, dynamic>;
        final itemsList = (data['items'] as Map<String, dynamic>)['items'] as List<dynamic>;
        _items = itemsList.map((e) => MyItem.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _error = 'Ошибка сервера: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Ошибка подключения: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 31, 31, 31),
      appBar: AppBar(title: const Text('Профиль'), backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0)),
      body: _loading
          ? const Center(child: LoadingIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: _textStyle))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final name = _user?['name'] as String? ?? '';
    final img = _user?['img'] as String?;
    final createdAt = _user?['created_at'] as String?;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 48,
            backgroundImage: (img != null && img.isNotEmpty) ? NetworkImage(img) : null,
            child: (img == null || img.isEmpty) ? const Icon(Icons.person, size: 48) : null,
          ),
          const SizedBox(height: 12),
          Text(name, style: _textStyle),
          const SizedBox(height: 12),
          Text('Дата регистрации: ${_formatDate(createdAt)}', style: _textStyle),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Работы', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('Пока нет работ', style: TextStyle(color: Colors.white54)))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final item = _items[i];
                return MyItemCard(
                  item: item,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ItemDetailPage(itemId: item.id, initialName: item.name, initialImageUrl: item.icon)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}