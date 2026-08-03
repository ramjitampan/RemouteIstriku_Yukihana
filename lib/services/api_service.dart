import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config_store.dart';

class ApiService {
  final YukiConfig config;

  ApiService(this.config);

  Future<bool> health() async {
    final res = await http
        .get(Uri.parse('${config.baseUrl}/api/health'))
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) return false;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['ok'] == true;
  }

  Future<String> say(String text) async {
    final res = await http
        .post(
          Uri.parse('${config.baseUrl}/api/say'),
          headers: {
            'Content-Type': 'application/json',
            if (config.token.isNotEmpty) 'X-Yuki-Token': config.token,
          },
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw ApiException('Server menjawab ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final reply = body['reply'];
    if (reply is! String) {
      throw ApiException('Balasan tidak dikenali');
    }
    return reply;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
