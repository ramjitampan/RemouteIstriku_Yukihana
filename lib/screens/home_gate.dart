import 'package:flutter/material.dart';

import '../services/config_store.dart';
import 'chat_screen.dart';
import 'connect_screen.dart';

class HomeGate extends StatefulWidget {
  const HomeGate({super.key});

  @override
  State<HomeGate> createState() => _HomeGateState();
}

class _HomeGateState extends State<HomeGate> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<YukiConfig?>(
      future: ConfigStore.instance.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final config = snapshot.data;
        if (config == null || config.ip.isEmpty || config.port.isEmpty) {
          return const ConnectScreen();
        }
        return ChatScreen(config: config);
      },
    );
  }
}
