import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Latar belakang bersama: gradien lavender lembut + dekorasi
/// kelopak/snowflake halus di pojok, konsisten di semua halaman.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradient.background),
        ),
        const _SubtleDecor(),
        child,
      ],
    );
  }
}

class _SubtleDecor extends StatelessWidget {
  const _SubtleDecor();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: _deco(Icons.filter_vintage, 170, 0.06, 0.3),
          ),
          Positioned(
            bottom: 90,
            left: -34,
            child: _deco(Icons.ac_unit, 120, 0.05, -0.2),
          ),
          Positioned(
            bottom: -46,
            right: 50,
            child: _deco(Icons.filter_vintage, 140, 0.05, 0.1),
          ),
          Positioned(
            top: 150,
            left: -26,
            child: _deco(Icons.ac_unit, 90, 0.05, 0.4),
          ),
        ],
      ),
    );
  }

  Widget _deco(IconData icon, double size, double opacity, double rotation) {
    return Transform.rotate(
      angle: rotation,
      child: Opacity(
        opacity: opacity,
        child: Icon(icon, size: size, color: AppColors.primary),
      ),
    );
  }
}
