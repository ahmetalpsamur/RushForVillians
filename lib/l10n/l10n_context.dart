import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'app_localizations_tr.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsTr();
}
