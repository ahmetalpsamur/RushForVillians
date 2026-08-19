import 'package:flutter/material.dart';

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
        label: 'Heapchi Studios açılış ekranı',
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
