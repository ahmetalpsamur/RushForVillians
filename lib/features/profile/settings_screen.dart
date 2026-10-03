import 'package:flutter/material.dart';

import '../../core/localization/locale_preference.dart';
import '../../services/adventure_notification_service.dart';
import '../../services/game_settings.dart';

class SettingsScreen extends StatefulWidget {
  final LocalePreference localePreference;
  final ValueChanged<LocalePreference> onLocalePreferenceChanged;
  final VoidCallback? onNotificationsEnabled;

  const SettingsScreen({
    super.key,
    required this.localePreference,
    required this.onLocalePreferenceChanged,
    this.onNotificationsEnabled,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late LocalePreference _selected = widget.localePreference;

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    return Scaffold(
      appBar: AppBar(title: Text(english ? 'Settings' : 'Ayarlar')),
      body: ListView(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: GameSettings.notificationsEnabled,
            builder:
                (_, enabled, _) => SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: Text(english ? 'Notifications' : 'Bildirimler'),
                  value: enabled,
                  onChanged: (value) async {
                    await GameSettings.setNotifications(value);
                    if (!value) {
                      await AdventureNotificationService.cancelAllReminders();
                    } else {
                      widget.onNotificationsEnabled?.call();
                    }
                  },
                ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: GameSettings.soundEffectsEnabled,
            builder:
                (_, enabled, _) => SwitchListTile(
                  secondary: const Icon(Icons.volume_up_outlined),
                  title: Text(english ? 'Sound effects' : 'Ses efektleri'),
                  value: enabled,
                  onChanged: GameSettings.setSoundEffects,
                ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(english ? 'Language' : 'Dil'),
          ),
          for (final preference in LocalePreference.values)
            ListTile(
              leading: Icon(
                _selected == preference
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(switch (preference) {
                LocalePreference.system =>
                  english ? 'Device language' : 'Cihaz dili',
                LocalePreference.turkish => 'Türkçe',
                LocalePreference.english => 'English',
              }),
              onTap: () {
                setState(() => _selected = preference);
                widget.onLocalePreferenceChanged(preference);
              },
            ),
        ],
      ),
    );
  }
}
