import 'package:flutter/foundation.dart';

class ItemsUpdateNotifier extends ChangeNotifier {
  void notifyItemsChanged() => notifyListeners();
}