import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/config_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'chat_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController(text: '192.168.1.8');
  final _portController = TextEditingController(text: '8123');
  final _tokenController = TextEditingController();
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _status = 'Menghubungi laptop...';
    });
    final cfg = _buildConfig();
    try {
      final ok = await ApiService(cfg).health();
      setState(() {
        _status = ok
            ? 'Koneksi berhasil! Yukihana aktif.'
            : 'Laptop merespons, tapi bukan Yukihana.';
      });
    } catch (_) {
      setState(() {
        _status = 'Gagal terhubung. Pastikan IP/port benar dan Yukihana sedang jalan.';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cfg = _buildConfig();
    setState(() {
      _busy = true;
      _status = 'Menguji koneksi...';
    });
    try {
      final ok = await ApiService(cfg).health();
      if (!ok) {
        setState(() {
          _busy = false;
          _status = 'Gagal terhubung. Periksa kembali IP/port.';
        });
        return;
      }
    } catch (_) {
      setState(() {
        _busy = false;
        _status = 'Gagal terhubung. Periksa kembali IP/port.';
      });
      return;
    }
    await ConfigStore.instance.save(cfg);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatScreen(config: cfg)),
    );
  }

  YukiConfig _buildConfig() => YukiConfig(
        ip: _ipController.text.trim(),
        port: _portController.text.trim(),
        token: _tokenController.text.trim(),
      );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Sambungkan ke Yukihana')),
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: AppColors.lavenderLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.filter_vintage,
                            color: AppColors.primary,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hubungkan ponsel ke laptop',
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Isi alamat server Yukihana di laptop kamu.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _ipController,
                          decoration: const InputDecoration(
                            labelText: 'IP Laptop',
                            hintText: '192.168.1.10',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'IP wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            hintText: '8123',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Port wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tokenController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Token (opsional)',
                            hintText: 'Kosongkan jika tidak dipakai',
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_status != null) ...[
                          Text(
                            _status!,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        FilledButton.icon(
                          onPressed: _busy ? null : _test,
                          icon: const Icon(Icons.wifi_tethering),
                          label: const Text('Uji Koneksi'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _save,
                          icon: const Icon(Icons.chat),
                          label: const Text('Simpan & Mulai Ngobrol'),
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
    );
  }
}
