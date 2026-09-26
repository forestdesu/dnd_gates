import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

extension _ImageContentType on String {
  MediaType get imageMediaType {
    switch (split('.').last.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'png');
    }
  }
}


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

  static Future<http.Response> getMyItems(String token, int page, int pageSize) async {
    return await http.get(
      Uri.parse('http://${_getApiHost()}/users/me/items?page=$page&page_size=$pageSize'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<http.Response> createItem(String token, Map<String, dynamic> body) async {
    return await http.post(
      Uri.parse('http://${_getApiHost()}/items'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
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

  static Future<http.Response> deleteItem(String token, int itemId) async {
    return await http.delete(
      Uri.parse('http://${_getApiHost()}/items/$itemId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<http.Response> updateItem(String token, int itemId, Map<String, dynamic> body) async {
    return await http.patch(
      Uri.parse('http://${_getApiHost()}/items/$itemId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> uploadItemImage(String token, int itemId, File file) async {
    final uri = Uri.parse('http://${_getApiHost()}/items/$itemId/images');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', file.path, contentType: file.path.imageMediaType));
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  static Future<http.Response> deleteItemImage(String token, int itemId, int imageId) async {
    return await http.delete(
      Uri.parse('http://${_getApiHost()}/items/$itemId/images/$imageId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<http.Response> reorderItemImages(String token, int itemId, List<int> imageIds) async {
    return await http.patch(
      Uri.parse('http://${_getApiHost()}/items/$itemId/images/reorder'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'image_ids': imageIds}),
    );
  }

  static Future<http.Response> getMyGroups(String token, {int? itemId}) async {
    final query = itemId != null ? '?item_id=$itemId' : '';
    return await http.get(
      Uri.parse('http://${_getApiHost()}/users/me/groups$query'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<http.Response> addItemToGroups(String token, int itemId, List<int> groupIds) async {
    return await http.post(
      Uri.parse('http://${_getApiHost()}/items/$itemId/groups'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'group_ids': groupIds}),
    );
  }

  static Future<http.Response> createGroup(String token, String name) async {
    return await http.post(
      Uri.parse('http://${_getApiHost()}/users/me/groups'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'name': name}),
    );
  }

  static Future<http.Response> renameGroup(String token, int groupId, String name) async {
    return await http.patch(
      Uri.parse('http://${_getApiHost()}/users/me/groups/$groupId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'name': name}),
    );
  }

  static Future<http.Response> deleteGroup(String token, int groupId) async {
    return await http.delete(
      Uri.parse('http://${_getApiHost()}/users/me/groups/$groupId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<http.Response> reorderGroups(String token, List<int> groupIds) async {
    return await http.patch(
      Uri.parse('http://${_getApiHost()}/users/me/groups/reorder'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'group_ids': groupIds}),
    );
  }

  static Future<http.Response> getGroupItems(String token, int groupId, int page, int pageSize) async {
    return await http.get(
      Uri.parse('http://${_getApiHost()}/groups/$groupId/items?page=$page&page_size=$pageSize'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<http.Response> removeGroupItem(String token, int groupId, int itemId) async {
    return await http.delete(
      Uri.parse('http://${_getApiHost()}/groups/$groupId/items/$itemId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<http.Response> getUserProfile(int userId, {int page = 1, int pageSize = 100}) async {
    return await http.get(Uri.parse('http://${_getApiHost()}/users/$userId?page=$page&page_size=$pageSize'));
  }
}