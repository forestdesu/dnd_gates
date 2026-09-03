import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  bool _isAuthenticated = false;
  Map<String, String> _userProfile = {}; // keys: name, email, photoUrl, registeredAt

  bool get isAuthenticated => _isAuthenticated;
  Map<String, String> get userProfile => _userProfile;

  /// Возвращает true при успехе. Если false — вызывающий код должен
  /// сам показать fallback (например, мок-диалог входа).
  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Google Sign-In timeout - likely no Play Services');
        },
      );
      if (account == null) return false;

      final auth = await account.authentication;
      _isAuthenticated = true;
      _userProfile = {
        'name': account.displayName ?? account.email,
        'email': account.email,
        'photoUrl': account.photoUrl ?? '',
        'registeredAt': DateTime.now().toIso8601String(),
        'idToken': auth.idToken ?? '',
        'accessToken': auth.accessToken ?? '',
      };
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return false;
    }
  }

  void loginMock({required String name, required String email, required String photoUrl}) {
    _isAuthenticated = true;
    _userProfile = {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'registeredAt': DateTime.now().toIso8601String(),
    };
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _isAuthenticated = false;
    _userProfile = {};
    notifyListeners();
  }

  void updateProfile({required String name, required String photoUrl}) {
    _userProfile = {
      ..._userProfile,
      'name': name,
      'photoUrl': photoUrl,
    };
    notifyListeners();
  }
}