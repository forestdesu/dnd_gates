import 'package:flutter/material.dart';
import '../screens/community.dart' show fetchLookups;

class LookupsController extends ChangeNotifier {
  List<Map<String, dynamic>> rarities = [];
  List<Map<String, dynamic>> types = [];
  List<Map<String, dynamic>> properties = [];
  List<Map<String, dynamic>> damageTypes = [];
  List<Map<String, dynamic>> dice = [];

  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      final data = await fetchLookups();
      rarities = data['rarities'] ?? [];
      types = data['types'] ?? [];
      properties = data['properties'] ?? [];
      damageTypes = data['damageTypes'] ?? [];
      dice = data['dice'] ?? [];
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}