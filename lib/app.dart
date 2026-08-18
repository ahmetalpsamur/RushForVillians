import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/character/character_creation_screen.dart';
import 'features/root/root_shell.dart';
import 'models/avatar_profile.dart';
import 'models/game_state.dart';
import 'services/character_storage.dart';
import 'services/game_storage.dart';

class RushForVilliansApp extends StatefulWidget {
  const RushForVilliansApp({super.key});

  @override
  State<RushForVilliansApp> createState() => _RushForVilliansAppState();
}

class _RushForVilliansAppState extends State<RushForVilliansApp> {
  AvatarProfile? _avatar;
  GameState? _gameState;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCharacter();
  }

  Future<void> _loadCharacter() async {
    final avatar = await CharacterStorage.load();
    // Oyun durumu avatara bağlı okunur; avatar yoksa yeni oyuncu demektir.
    final gameState =
        avatar == null ? null : await GameStorage.load(avatar: avatar);
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
              ? const _LoadingScreen()
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

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
