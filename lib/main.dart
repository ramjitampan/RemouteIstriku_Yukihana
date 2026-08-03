import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const YukiApp());
}

class YukiApp extends StatelessWidget {
  const YukiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yukihana',
      theme: AppTheme.light(),
      home: const VideoSplashScreen(),
    );
  }
}
