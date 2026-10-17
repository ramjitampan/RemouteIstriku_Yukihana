import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/config_store.dart';
import '../services/connection_validator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'chat_screen.dart';

class ConnectScreen extends StatefulWidget {
  final ApiService Function(YukiConfig)? apiFactory;

  const ConnectScreen({super.key, this.apiFactory});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8123');
  final _tokenController = TextEditingController();
  bool _busy = false;
  bool _hideToken = true;
  String? _status;
  bool? _connected;

  ApiService _apiFor(YukiConfig config) =>
      widget.apiFactory?.call(config) ?? ApiService(config);

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final saved = await ConfigStore.instance.load();
    if (!mounted || saved == null) return;
    _ipController.text = saved.ip;
    _portController.text = saved.port;
    _tokenController.text = saved.token;
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  YukiConfig _buildConfig() => YukiConfig(
    ip: _ipController.text.trim(),
    port: _portController.text.trim(),
    token: _tokenController.text.trim(),
  );

  Future<bool> _checkConnection(YukiConfig config) async {
    setState(() {
      _busy = true;
      _connected = null;
      _status = 'Menguji koneksi ke ${config.ip}:${config.port}…';
    });
    try {
      await _apiFor(config).health();
      if (!mounted) return false;
      setState(() {
        _connected = true;
        _status = 'Terhubung. Yukihana siap diajak ngobrol.';
      });
      return true;
    } on ApiException catch (error) {
      if (!mounted) return false;
      setState(() {
        _connected = false;
        _status = error.message;
      });
      return false;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _connected = false;
        _status = 'Koneksi gagal: $error';
      });
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() async {
    if (!_formKey.currentState!.validate()) return;
    await _checkConnection(_buildConfig());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final config = _buildConfig();
    if (!await _checkConnection(config) || !mounted) return;
    await ConfigStore.instance.save(config);
    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop<YukiConfig>(config);
    } else {
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              ChatScreen(config: config, apiFactory: widget.apiFactory),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Sambungkan ke Yukihana')),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: const BoxDecoration(
                                color: AppColors.lavenderLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.filter_vintage,
                                color: AppColors.primary,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Temukan Yukihana',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              color: AppColors.textMain,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Masukkan alamat IP laptop pada jaringan Wi-Fi yang sama. Jika IP berubah, kamu bisa memperbaruinya di sini kapan saja.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _ipController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'IP laptop',
                              hintText: '192.168.1.20',
                              prefixIcon: Icon(Icons.lan_outlined),
                              helperText:
                                  'Alamat dapat berubah jika DHCP memperbarui jaringan.',
                            ),
                            validator: ConnectionValidator.ipv4,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _portController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Port server',
                              hintText: '8123',
                              prefixIcon: Icon(Icons.settings_ethernet),
                            ),
                            validator: ConnectionValidator.port,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _tokenController,
                            obscureText: _hideToken,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Token autentikasi',
                              hintText:
                                  'Masukkan token dari konfigurasi server',
                              prefixIcon: const Icon(Icons.key_outlined),
                              suffixIcon: IconButton(
                                tooltip: _hideToken
                                    ? 'Tampilkan token'
                                    : 'Sembunyikan token',
                                onPressed: () =>
                                    setState(() => _hideToken = !_hideToken),
                                icon: Icon(
                                  _hideToken
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _status == null
                                ? const SizedBox.shrink()
                                : _ConnectionStatus(
                                    key: ValueKey('$_connected:$_status'),
                                    text: _status!,
                                    connected: _connected,
                                  ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _busy ? null : _test,
                            icon: _busy
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.wifi_tethering),
                            label: Text(_busy ? 'Menguji…' : 'Uji koneksi'),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _save,
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Simpan & mulai ngobrol'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  final String text;
  final bool? connected;

  const _ConnectionStatus({
    super.key,
    required this.text,
    required this.connected,
  });

  @override
  Widget build(BuildContext context) {
    final color = connected == true
        ? const Color(0xFF287A55)
        : AppColors.textMain;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: connected == true
            ? const Color(0xFFE8F4EE)
            : AppColors.lavenderLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: connected == true
              ? const Color(0xFFBDDCCB)
              : AppColors.borderIdle,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            connected == true ? Icons.check_circle_outline : Icons.info_outline,
            size: 19,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
