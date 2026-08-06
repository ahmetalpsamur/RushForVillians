import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/root/root_shell.dart';

class RushForVilliansApp extends StatelessWidget {
  const RushForVilliansApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rush for Villains',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RootShell(),
    );
  }
}
