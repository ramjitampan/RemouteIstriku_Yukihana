import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'config_store.dart';

class ApiService {
  final YukiConfig config;
  final http.Client _client;
  final Duration healthTimeout;
  final Duration chatTimeout;

  ApiService(
    this.config, {
    http.Client? client,
    this.healthTimeout = const Duration(seconds: 5),
    this.chatTimeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  Map<String, String> get _authHeaders => {'X-Yuki-Token': config.token};
  Uri _endpoint(String path) => Uri.parse('${config.baseUrl}$path');

  Future<bool> health() async {
    try {
      final response = await _client
          .get(_endpoint('/api/health'), headers: _authHeaders)
          .timeout(healthTimeout);
      _checkStatus(response);
      final body = _decodeObject(response.body);
      if (body['ok'] != true) {
        throw ApiException('Respons health tidak berisi status ok=true.');
      }
      return true;
    } on TimeoutException {
      throw ApiException(
        'Waktu uji koneksi habis. Periksa server dan jaringan.',
      );
    } on SocketException {
      throw ApiException(
        'Server tidak terjangkau. Periksa IP, port, dan jaringan.',
      );
    } on http.ClientException {
      throw ApiException(
        'Server tidak terjangkau. Periksa IP, port, dan jaringan.',
      );
    } on FormatException {
      throw ApiException('Server mengirim respons JSON yang tidak valid.');
    }
  }

  Future<String> say(String text) async {
    try {
      final response = await _client
          .post(
            _endpoint('/api/say'),
            headers: {..._authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(chatTimeout);
      _checkStatus(response);
      final body = _decodeObject(response.body);
      final reply = body['reply'];
      if (reply is! String) {
        throw ApiException(
          'Respons chat tidak memiliki field reply berupa teks.',
        );
      }
      return reply;
    } on TimeoutException {
      throw ApiException(
        'Respons Yukihana melewati batas waktu. Coba lagi sebentar.',
      );
    } on SocketException {
      throw ApiException(
        'Server tidak terjangkau. Periksa IP, port, dan jaringan.',
      );
    } on http.ClientException {
      throw ApiException(
        'Server tidak terjangkau. Periksa IP, port, dan jaringan.',
      );
    } on FormatException {
      throw ApiException('Server mengirim respons JSON yang tidak valid.');
    }
  }

  Map<String, dynamic> _decodeObject(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Respons bukan objek JSON.');
    }
    return decoded;
  }

  void _checkStatus(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return;
      case 401:
      case 403:
        throw ApiException(
          'Autentikasi gagal (HTTP ${response.statusCode}). Periksa token.',
        );
      case 404:
        throw ApiException('Endpoint Yukihana tidak ditemukan (HTTP 404).');
      default:
        throw ApiException('Server menjawab HTTP ${response.statusCode}.');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
