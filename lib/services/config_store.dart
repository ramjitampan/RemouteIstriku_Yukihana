import 'package:shared_preferences/shared_preferences.dart';

class YukiConfig {
  final String ip;
  final String port;
  final String token;

  const YukiConfig({required this.ip, required this.port, this.token = ''});

  String get baseUrl => 'http://$ip:$port';
}

class ConfigStore {
  ConfigStore._();
  static final ConfigStore instance = ConfigStore._();

  static const _kIp = 'yuki_ip';
  static const _kPort = 'yuki_port';
  static const _kToken = 'yuki_token';

  Future<YukiConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString(_kIp) ?? '';
    final port = prefs.getString(_kPort) ?? '';
    final token = prefs.getString(_kToken) ?? '';
    if (ip.isEmpty || port.isEmpty) return null;
    return YukiConfig(ip: ip, port: port, token: token);
  }

  Future<void> save(YukiConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kIp, config.ip);
    await prefs.setString(_kPort, config.port);
    await prefs.setString(_kToken, config.token);
  }
}
