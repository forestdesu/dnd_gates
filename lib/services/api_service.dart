import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  static Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  static Future<String?> getToken() => _storage.read(key: _tokenKey);
  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static Future<http.Response> login(String idToken) async {
    return await http.post(
      Uri.parse('http://${_getApiHost()}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );
  }
  static String _getApiHost() {
    return '2.26.10.175:8000';
  }

  static Future<http.Response> getMe(String token) async {
    return await http.get(
      Uri.parse('http://${_getApiHost()}/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<http.Response> getItem(String itemId) async {
    return await http.get(Uri.parse('http://${_getApiHost()}/items/$itemId'));
  }

  static Future<http.Response> getLookups() async {
    return await http.get(Uri.parse('http://${_getApiHost()}/lookups'));
  }

  static Future<http.Response> getItems(Map<String, List<String>> queryParams) async {
    final parts = <String>[];
    queryParams.forEach((k, list) {
      for (final v in list) {
        parts.add('${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}');
      }
    });
    return await http
        .get(Uri.parse('http://${_getApiHost()}/items?${parts.join('&')}'))
        .timeout(const Duration(seconds: 10));
  }

  static Future<http.Response> getItemsSearch(Map<String, List<String>> queryParams) async {
    final parts = <String>[];
    queryParams.forEach((k, list) {
      for (final v in list) {
        parts.add('${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}');
      }
    });
    return await http.get(Uri.parse('http://${_getApiHost()}/items/search?${parts.join('&')}'));
  }
}