import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/locale_preference.dart';
import 'core/theme/app_theme.dart';
import 'features/character/character_creation_screen.dart';
import 'features/root/root_shell.dart';
import 'features/start/start_screen.dart';
import 'features/safety/safety_screen.dart';
import 'services/safety_notice_storage.dart';
import 'features/tutorial/guide_selection_screen.dart';
import 'models/avatar_profile.dart';
import 'models/game_state.dart';
import 'models/tutorial_guide_variant.dart';
import 'services/adventure_notification_service.dart';
import 'services/character_storage.dart';
import 'services/game_storage.dart';
import 'services/launch_sound.dart';
import 'services/tutorial_guide_storage.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n_context.dart';

class RushForVilliansApp extends StatefulWidget {
  const RushForVilliansApp({super.key});

  @override
  State<RushForVilliansApp> createState() => _RushForVilliansAppState();
}

class _RushForVilliansAppState extends State<RushForVilliansApp> {
  static const _minimumStartScreenDuration = Duration(seconds: 2);

  AvatarProfile? _avatar;
  GameState? _gameState;
  TutorialGuideVariant? _selectedGuide;
  LocalePreference _localePreference = LocalePreference.system;
  bool _isLoading = true;
  bool _safetyAccepted = false;

  /// Kayıt okunamadıysa `true`. Bu durumda kayıt **silinmez**; kullanıcı
  /// varsayılanla oynar ve bir sonraki açılışta okuma yeniden denenir.
  bool _storageFailed = false;

  /// Kayıt hatası uyarısı oturumda bir kez gösterilir.
  bool _storageWarningShown = false;

  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    unawaited(_loadLocalePreference());
    _initializeApp();
  }

  Future<void> _loadLocalePreference() async {
    try {
      final preference = await LocalePreferenceStorage.load();
      if (mounted) setState(() => _localePreference = preference);
    } catch (error) {
      debugPrint('Dil tercihi okunamadı, sistem dili kullanılacak ($error)');
    }
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
    TutorialGuideVariant? selectedGuide;
    try {
      avatar = await CharacterStorage.load();
      selectedGuide = await TutorialGuideStorage.load();
      // Oyun durumu avatara bağlı okunur; avatar yoksa yeni oyuncu demektir.
      gameState =
          avatar == null ? null : await GameStorage.load(avatar: avatar);
      _storageFailed =
          GameStorage.writeBlocked || CharacterStorage.writeBlocked;
    } catch (error) {
      // Kayıt okunamadıysa temiz varsayılanla başlanır; kayıt silinmez, bir
      // sonraki açılışta tekrar denenir.
      debugPrint('Açılış: kayıt okunamadı, varsayılanla başlanıyor ($error)');
      avatar = null;
      gameState = null;
      _storageFailed = true;
      GameStorage.protectUnreadableSave();
    }
    await notificationInitialization;
    final safetyAccepted =
        _storageFailed ? false : await SafetyNoticeStorage.isAccepted();

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minimumStartScreenDuration) {
      await Future<void>.delayed(_minimumStartScreenDuration - elapsed);
    }

    if (!mounted) return;
    setState(() {
      _avatar = avatar;
      _gameState = gameState;
      _selectedGuide = selectedGuide;
      _isLoading = false;
      _safetyAccepted = safetyAccepted;
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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Text(context.l10n.storageUnavailable),
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

  Future<void> _saveGuide(TutorialGuideVariant guide) async {
    try {
      if (!_storageFailed) await TutorialGuideStorage.save(guide);
    } catch (error) {
      debugPrint('Yol arkadaşı kaydedilemedi ($error)');
    }
    if (!mounted) return;
    setState(() => _selectedGuide = guide);
  }

  Future<void> _setLocalePreference(LocalePreference preference) async {
    setState(() => _localePreference = preference);
    try {
      await LocalePreferenceStorage.save(preference);
    } catch (error) {
      debugPrint('Dil tercihi kaydedilemedi ($error)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: _localePreference.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeListResolutionCallback:
          (deviceLocales, supportedLocales) =>
              _localePreference.locale ?? resolveSystemLocale(deviceLocales),
      home:
          _isLoading
              ? const StartScreen()
              : !_safetyAccepted
              ? SafetyScreen(
                onAccepted: () => setState(() => _safetyAccepted = true),
              )
              : _avatar == null && _selectedGuide == null
              ? GuideSelectionScreen(onSelected: _saveGuide)
              : _avatar == null
              ? CharacterCreationScreen(onCompleted: _saveCharacter)
              : RootShell(
                avatar: _avatar!,
                initialState: _gameState,
                startTutorial: true,
                initialTutorialGuide: _selectedGuide,
                onAvatarChanged: _saveCharacter,
                localePreference: _localePreference,
                onLocalePreferenceChanged: _setLocalePreference,
              ),
    );
  }
}
