import 'dart:async';

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/character/character_creation_screen.dart';
import 'features/root/root_shell.dart';
import 'features/start/start_screen.dart';
import 'models/avatar_profile.dart';
import 'models/game_state.dart';
import 'services/adventure_notification_service.dart';
import 'services/character_storage.dart';
import 'services/game_storage.dart';
import 'services/launch_sound.dart';

class RushForVilliansApp extends StatefulWidget {
  const RushForVilliansApp({super.key});

  @override
  State<RushForVilliansApp> createState() => _RushForVilliansAppState();
}

class _RushForVilliansAppState extends State<RushForVilliansApp> {
  static const _minimumStartScreenDuration = Duration(seconds: 2);

  AvatarProfile? _avatar;
  GameState? _gameState;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startedAt = DateTime.now();
    unawaited(LaunchSound.playOnce());

    // Bildirim servisi açılış görseli gösterilirken hazırlanır. Böylece native
    // açılış ekranı gereksiz yere ekranda kalmaz.
    final notificationInitialization = AdventureNotificationService.initialize();
    final avatar = await CharacterStorage.load();
    // Oyun durumu avatara bağlı okunur; avatar yoksa yeni oyuncu demektir.
    final gameState =
        avatar == null ? null : await GameStorage.load(avatar: avatar);
    await notificationInitialization;

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minimumStartScreenDuration) {
      await Future<void>.delayed(_minimumStartScreenDuration - elapsed);
    }

    if (!mounted) return;
    setState(() {
      _avatar = avatar;
      _gameState = gameState;
      _isLoading = false;
    });
  }

  Future<void> _saveCharacter(AvatarProfile avatar) async {
    await CharacterStorage.save(avatar);
    if (!mounted) return;
    setState(() => _avatar = avatar);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rush for Villains',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home:
          _isLoading
              ? const StartScreen()
              : _avatar == null
              ? CharacterCreationScreen(onCompleted: _saveCharacter)
              : RootShell(
                avatar: _avatar!,
                initialState: _gameState,
                onAvatarChanged: _saveCharacter,
              ),
    );
  }
}
