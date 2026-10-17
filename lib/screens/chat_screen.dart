import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/config_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'connect_screen.dart';

class ChatScreen extends StatefulWidget {
  final YukiConfig config;
  final ApiService Function(YukiConfig)? apiFactory;

  const ChatScreen({super.key, required this.config, this.apiFactory});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <_Msg>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;
  late YukiConfig _activeConfig;
  late ApiService _api;

  ApiService _apiFor(YukiConfig config) =>
      widget.apiFactory?.call(config) ?? ApiService(config);

  @override
  void initState() {
    super.initState();
    _activeConfig = widget.config;
    _api = _apiFor(_activeConfig);
    _messages.add(
      const _Msg(
        'Halo, aku Yukihana. Yuk ngobrol atau minta bantuanku.',
        from: false,
      ),
    );
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
      reply = 'Waktu respons habis. Periksa koneksi laptop, lalu coba lagi.';
    } on ApiException catch (error) {
      reply = error.message;
    } catch (error) {
      reply = 'Koneksi gagal: $error';
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _reconnect() async {
    final config = await Navigator.of(context).push<YukiConfig?>(
      MaterialPageRoute(
        builder: (_) => ConnectScreen(apiFactory: widget.apiFactory),
      ),
    );
    if (config == null || !mounted) return;
    setState(() {
      _activeConfig = config;
      _api = _apiFor(config);
      _messages.add(const _Msg('Koneksi diperbarui.', from: false));
    });
    _scrollDown();
  }

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Koneksi Yukihana'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alamat server'),
            const SizedBox(height: 4),
            SelectableText(_activeConfig.baseUrl),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _activeConfig.token.isEmpty
                      ? 'Tanpa token'
                      : 'Token digunakan',
                ),
              ],
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
            child: const Text('Ubah alamat'),
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
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.lavenderLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_vintage,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yukihana', style: TextStyle(fontSize: 17, height: 1.1)),
                SizedBox(height: 4),
                Text(
                  'Asisten pribadimu',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Info koneksi',
            onPressed: _showInfo,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Ubah koneksi',
            onPressed: _reconnect,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AppBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                itemCount: _messages.length + (_typing ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return const _TypingIndicator();
                  }
                  return _messages[index];
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
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
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderIdle),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 18,
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
              enabled: enabled,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 15,
                height: 1.35,
              ),
              decoration: const InputDecoration(
                hintText: 'Tulis pesan untuk Yuki…',
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onSubmitted: (_) => enabled ? onSend() : null,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 46,
            height: 46,
            child: IconButton.filled(
              onPressed: enabled ? onSend : null,
              tooltip: 'Kirim pesan',
              icon: const Icon(Icons.arrow_upward_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.4,
                ),
                shape: const CircleBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) =>
      const _Msg('Yukihana sedang mengetik…', from: false);
}

class _Msg extends StatelessWidget {
  final String text;
  final bool from;

  const _Msg(this.text, {required this.from});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = from
        ? AppColors.primary
        : AppColors.surface.withValues(alpha: 0.94);
    final textColor = from ? Colors.white : AppColors.textMain;
    return Align(
      alignment: from ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(19),
            topRight: const Radius.circular(19),
            bottomLeft: Radius.circular(from ? 19 : 5),
            bottomRight: Radius.circular(from ? 5 : 19),
          ),
          border: from
              ? null
              : Border.all(color: AppColors.borderIdle.withValues(alpha: 0.75)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: from ? 0.14 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
        ),
      ),
    );
  }
}
