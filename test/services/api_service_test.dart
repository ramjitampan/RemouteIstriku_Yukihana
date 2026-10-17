import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_yuki/services/api_service.dart';
import 'package:mobile_yuki/services/config_store.dart';

void main() {
  const config = YukiConfig(
    ip: '192.168.1.20',
    port: '8123',
    token: 'secret-token',
  );

  test(
    'health sends the same auth token and accepts backend contract',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/health');
        expect(request.headers['X-Yuki-Token'], 'secret-token');
        return http.Response('{"ok":true,"name":"Yuki"}', 200);
      });
      expect(await ApiService(config, client: client).health(), isTrue);
    },
  );

  test(
    'chat uses configured host, port, token, endpoint and JSON contract',
    () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'http://192.168.1.20:8123/api/say');
        expect(request.headers['X-Yuki-Token'], 'secret-token');
        expect(request.headers['Content-Type'], 'application/json');
        expect(jsonDecode(request.body), {'text': 'Halo'});
        return http.Response('{"reply":"Hai"}', 200);
      });
      expect(await ApiService(config, client: client).say('Halo'), 'Hai');
    },
  );
  test('401 and 404 errors are distinguishable', () async {
    final unauthorized = ApiService(
      config,
      client: MockClient(
        (_) async => http.Response('{"error":"unauthorized"}', 401),
      ),
    );
    await expectLater(
      unauthorized.health(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Autentikasi'),
        ),
      ),
    );

    final missing = ApiService(
      config,
      client: MockClient(
        (_) async => http.Response('{"error":"not found"}', 404),
      ),
    );
    await expectLater(
      missing.health(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Endpoint'),
        ),
      ),
    );
  });

  test('403 is reported as an authentication error', () async {
    final forbidden = ApiService(
      config,
      client: MockClient(
        (_) async => http.Response('{"error":"forbidden"}', 403),
      ),
    );
    await expectLater(
      forbidden.health(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Autentikasi gagal (HTTP 403)'),
        ),
      ),
    );
  });
  test('timeout and unreachable server have distinct messages', () async {
    final slow = ApiService(
      config,
      healthTimeout: const Duration(milliseconds: 1),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    await expectLater(
      slow.health(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('habis'),
        ),
      ),
    );

    final offline = ApiService(
      config,
      client: MockClient((_) async => throw const SocketException('offline')),
    );
    await expectLater(
      offline.health(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('tidak terjangkau'),
        ),
      ),
    );
  });

  test('invalid response JSON is reported', () async {
    final api = ApiService(
      config,
      client: MockClient((_) async => http.Response('not-json', 200)),
    );
    await expectLater(
      api.health(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('JSON'),
        ),
      ),
    );
  });
}
