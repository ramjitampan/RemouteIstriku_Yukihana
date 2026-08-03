import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/config_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'connect_screen.dart';

class ChatScreen extends StatefulWidget {
  final YukiConfig config;

  const ChatScreen({super.key, required this.config});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <_Msg>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;
  late ApiService _api;

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.config);
    _messages.add(const _Msg(
      'Halo, aku Yukihana! Ketik sesuatu untuk ngobrol atau kasih perintah ke laptop.',
      from: false,
    ));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _typing) return;
    setState(() {
      _messages.add(_Msg(text, from: true));
      _typing = true;
    });
    _input.clear();
    _scrollDown();
    String reply;
    try {
      reply = await _api.say(text);
    } on TimeoutException {
      reply = 'Waktu habis. Pastikan laptop menyala dan jaringan sama.';
    } catch (e) {
      reply = 'Gagal terhubung ke Yukihana: $e';
    }
    if (!mounted) return;
    setState(() {
      _typing = false;
      _messages.add(_Msg(reply, from: false));
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _reconnect() async {
    final cfg = await Navigator.of(context).push<YukiConfig?>(
      MaterialPageRoute(builder: (_) => const ConnectScreen()),
    );
    if (cfg == null || !mounted) return;
    setState(() {
      _api = ApiService(cfg);
      _messages.add(const _Msg('Tersambung kembali.', from: false));
    });
  }

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Koneksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Server: ${widget.config.baseUrl}'),
            const SizedBox(height: 8),
            Text(
              widget.config.token.isEmpty
                  ? 'Token: tidak dipakai'
                  : 'Token: dipakai',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _reconnect();
            },
            child: const Text('Ubah koneksi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Yukihana'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Info koneksi',
            onPressed: _showInfo,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ubah koneksi',
            onPressed: _reconnect,
          ),
        ],
      ),
      body: AppBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 92, 16, 12),
                itemCount: _messages.length + (_typing ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length) {
                    return const _Msg('Yukihana sedang mengetik...', from: false);
                  }
                  return _messages[i];
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: _InputBar(
                  controller: _input,
                  enabled: !_typing,
                  onSend: _send,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.borderIdle, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(color: AppColors.textMain, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Tulis pesan...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: false,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.4),
                shape: const CircleBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg extends StatelessWidget {
  final String text;
  final bool from;

  const _Msg(this.text, {required this.from});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = from ? AppColors.primary : AppColors.lavenderLight;
    final textColor = from ? Colors.white : AppColors.textMain;

    return Align(
      alignment: from ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(from ? 20 : 4),
            bottomRight: Radius.circular(from ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: from ? 0.18 : 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(color: textColor, fontSize: 15, height: 1.35),
        ),
      ),
    );
  }
}
