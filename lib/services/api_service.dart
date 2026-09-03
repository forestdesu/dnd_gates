import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static String _getApiHost() {
    if (Platform.isAndroid) {
      return '10.0.2.2:8000';
    }
    return '127.0.0.1:8000';
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