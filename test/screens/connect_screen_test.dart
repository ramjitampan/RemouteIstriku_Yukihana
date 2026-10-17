import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_yuki/screens/chat_screen.dart';
import 'package:mobile_yuki/screens/connect_screen.dart';
import 'package:mobile_yuki/services/api_service.dart';
import 'package:mobile_yuki/services/config_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('successful connection saves config and opens chat', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient((request) async {
      expect(request.headers['X-Yuki-Token'], 'phone-test-token');
      if (request.url.path == '/api/health') {
        return http.Response('{"ok":true,"name":"Yuki"}', 200);
      }
      expect(request.url.toString(), 'http://192.168.1.11:8123/api/say');
      return http.Response('{"reply":"Balasan uji"}', 200);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ConnectScreen(
          apiFactory: (config) => ApiService(config, client: client),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '192.168.1.11');
    await tester.enterText(find.byType(TextFormField).at(1), '8123');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'phone-test-token',
    );
    await tester.ensureVisible(find.text('Simpan & mulai ngobrol'));
    await tester.tap(find.text('Simpan & mulai ngobrol'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Yukihana'), findsOneWidget);
    final saved = await ConfigStore.instance.load();
    expect(saved?.ip, '192.168.1.11');
    expect(saved?.port, '8123');
    expect(saved?.token, 'phone-test-token');
    await tester.enterText(find.byType(TextField).first, 'Halo Yuki');
    await tester.tap(find.byTooltip('Kirim pesan'));
    await tester.pumpAndSettle();
    expect(find.text('Balasan uji'), findsOneWidget);
  });

  testWidgets('authentication failure stays on form with clear status', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient(
      (_) async => http.Response('{"error":"unauthorized"}', 401),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ConnectScreen(
          apiFactory: (config) => ApiService(config, client: client),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '192.168.1.11');
    await tester.ensureVisible(find.text('Uji koneksi'));
    await tester.tap(find.text('Uji koneksi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Autentikasi gagal'), findsOneWidget);
    expect(find.byType(ChatScreen), findsNothing);
  });
}
