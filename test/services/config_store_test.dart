import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_yuki/services/config_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('configuration changes persist across loads', () async {
    SharedPreferences.setMockInitialValues({});
    const first = YukiConfig(
      ip: '192.168.1.20',
      port: '8123',
      token: 'token-a',
    );
    const updated = YukiConfig(ip: '10.0.0.5', port: '9000', token: 'token-b');
    final store = ConfigStore.instance;

    await store.save(first);
    final loadedFirst = await store.load();
    expect(loadedFirst?.ip, first.ip);
    expect(loadedFirst?.port, first.port);
    expect(loadedFirst?.token, first.token);
    await store.save(updated);
    final loadedUpdated = await store.load();
    expect(loadedUpdated?.ip, updated.ip);
    expect(loadedUpdated?.port, updated.port);
    expect(loadedUpdated?.token, updated.token);
  });
}
