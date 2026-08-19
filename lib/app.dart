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

  /// Kayıt okunamadıysa `true`. Bu durumda kayıt **silinmez**; kullanıcı
  /// varsayılanla oynar ve bir sonraki açılışta okuma yeniden denenir.
  bool _storageFailed = false;

  /// Kayıt hatası uyarısı oturumda bir kez gösterilir.
  bool _storageWarningShown = false;

  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

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
    final notificationInitialization = AdventureNotificationService.initialize()
        .catchError((Object error) {
          // Bildirim izni/kanalı olmayan cihazda oyun yine de açılmalı.
          debugPrint('Açılış: bildirim servisi hazırlanamadı ($error)');
        });

    // Açılışın hiçbir adımı ekranı kilitlememeli: platform kanalı düşerse
    // (SharedPreferences yoksa, izin reddedilirse) yükleme sonsuza kadar
    // sürer ve kullanıcı açılış görselinde asılı kalırdı.
    AvatarProfile? avatar;
    GameState? gameState;
    try {
      avatar = await CharacterStorage.load();
      // Oyun durumu avatara bağlı okunur; avatar yoksa yeni oyuncu demektir.
      gameState =
          avatar == null ? null : await GameStorage.load(avatar: avatar);
    } catch (error) {
      // Kayıt okunamadıysa temiz varsayılanla başlanır; kayıt silinmez, bir
      // sonraki açılışta tekrar denenir.
      debugPrint('Açılış: kayıt okunamadı, varsayılanla başlanıyor ($error)');
      avatar = null;
      gameState = null;
      _storageFailed = true;
    }
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
    _showStorageWarningIfNeeded();
  }

  /// Kayıt okunamadığında sessiz kalınmaz: oyuncu ilerlemesinin neden sıfır
  /// göründüğünü bilmeli (CLAUDE.md — Model Kuralları #4).
  void _showStorageWarningIfNeeded() {
    if (!_storageFailed || _storageWarningShown) return;
    _storageWarningShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 6),
          content: Text(
            'Kayıtlı ilerlemene şu an ulaşılamadı. Oyun geçici bir '
            'kayıtla açıldı; uygulamayı yeniden başlatmayı dene.',
          ),
        ),
      );
    });
  }

  Future<void> _saveCharacter(AvatarProfile avatar) async {
    try {
      await CharacterStorage.save(avatar);
    } catch (error) {
      // Yazma başarısızsa oyun oturum boyunca çalışmaya devam eder.
      debugPrint('Karakter kaydedilemedi ($error)');
    }
    if (!mounted) return;
    setState(() => _avatar = avatar);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rush for Villains',
      scaffoldMessengerKey: _messengerKey,
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
