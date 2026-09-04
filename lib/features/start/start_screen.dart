import 'package:flutter/material.dart';

import '../../l10n/l10n_context.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  static const assetPath = 'lib/Start/StartLogo.png';
  static const backgroundColor = Color(0xFFF8535A);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Semantics(
        image: true,
        label: context.l10n.studioSplashSemantics,
        child: const SizedBox.expand(
          child: Image(
            image: AssetImage(assetPath),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
