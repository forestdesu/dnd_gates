import 'package:flutter/material.dart';
import '../screens/community_screen.dart' show fetchLookups;

class LookupsController extends ChangeNotifier {
  List<Map<String, dynamic>> rarities = [];
  List<Map<String, dynamic>> types = [];
  List<Map<String, dynamic>> properties = [];

  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final data = await fetchLookups();
      rarities = data['rarities'] ?? [];
      types = data['types'] ?? [];
      properties = data['properties'] ?? [];
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}