import 'package:flutter/material.dart';

class GGLogoMark extends StatelessWidget {
  const GGLogoMark({super.key, this.size = 56, this.showGlow = true});

  static const assetPath = 'assets/brand/logo.png';

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glow = showGlow
        ? scheme.primary.withValues(alpha: 0.32)
        : Colors.transparent;
    final radius = BorderRadius.circular(size * 0.26);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: size * 0.45,
            spreadRadius: size * 0.02,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
