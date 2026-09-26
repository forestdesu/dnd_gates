import 'dart:convert';
import '../config/google_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/api_service.dart';

class AuthController extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isAuthenticated = false;
  Map<String, String> _userProfile = {};
  Future<void>? _googleInitialization;

  bool get isAuthenticated => _isAuthenticated;
  bool get isStaff => _userProfile['isStaff'] == 'true';
  Map<String, String> get userProfile => _userProfile;

  Future<void> _initializeGoogleSignIn() {
    return _googleInitialization ??= _googleSignIn.initialize(
      serverClientId: googleServerClientId,
    );
  }

  Future<bool> signInWithGoogle() async {
    try {
      await _initializeGoogleSignIn();

      debugPrint('Google Sign-In: starting authentication...');

      final GoogleSignInAccount account =
      await _googleSignIn.authenticate(
        scopeHint: const [
          'email',
          'profile',
        ],
      );

      debugPrint('Google Sign-In: account received');

      final GoogleSignInAuthentication auth = account.authentication;

      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        debugPrint('Google Sign-In: ID token is null or empty');
        return false;
      }

      debugPrint('Google Sign-In: ID token received');
      debugPrint('Google Sign-In: sending token to backend...');

      final response = await ApiService.login(idToken);
      debugPrint(jsonDecode(response.body).toString());

      debugPrint(
        'Backend response: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Backend login error: '
              '${response.statusCode} ${response.body}',
        );
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final user = data['user'] as Map<String, dynamic>;

      final token = data['token'] as String;

      await ApiService.saveToken(token);

      _isAuthenticated = true;

      _userProfile = {
        'id': user['id'].toString(),
        'name': user['name'] as String? ?? '',
        'email': user['email'] as String? ?? '',
        'photoUrl': user['img'] as String? ?? '',
        'isStaff': (user['is_staff'] as bool? ?? false).toString(),
        'registeredAt': user['created_at'] as String? ?? '',
      };

      notifyListeners();

      debugPrint('Google Sign-In: login successful');

      return true;
    } on GoogleSignInException catch (e) {
      debugPrint(
        'Google Sign-In exception: '
            'code=${e.code}, description=${e.description}',
      );

      return false;
    } catch (e, stackTrace) {
      debugPrint('Google Sign-In error: $e');
      debugPrint('$stackTrace');

      return false;
    }
  }

  Future<void> tryRestoreSession() async {
    final token = await ApiService.getToken();

    if (token == null || token.isEmpty) {
      return;
    }

    try {
      final response = await ApiService.getMe(token);

      if (response.statusCode != 200) {
        await ApiService.clearToken();
        return;
      }

      final user = jsonDecode(response.body) as Map<String, dynamic>;

      _isAuthenticated = true;


      _userProfile = {
        'id': user['id'].toString(),
        'name': user['name'] as String? ?? '',
        'email': user['email'] as String? ?? '',
        'photoUrl': user['img'] as String? ?? '',
        'isStaff': (user['is_staff'] as bool? ?? false).toString(),
        'registeredAt': user['created_at'] as String? ?? '',
      };

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Restore session error: $e');
      debugPrint('$stackTrace');
    }
  }

  void loginMock({
    required String name,
    required String email,
    required String photoUrl,
  }) {
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
    } catch (e) {
      debugPrint('Google Sign-Out error: $e');
    }

    await ApiService.clearToken();

    _isAuthenticated = false;
    _userProfile = {};

    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String photoUrl,
  }) {
    _userProfile = {
      ..._userProfile,
      'name': name,
      'photoUrl': photoUrl,
    };

    notifyListeners();
  }
}