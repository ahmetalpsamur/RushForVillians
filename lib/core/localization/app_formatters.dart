import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

abstract final class AppFormatters {
  static String localeName(BuildContext context) =>
      Localizations.localeOf(context).toLanguageTag();

  static String integer(BuildContext context, num value) =>
      NumberFormat.decimalPattern(localeName(context)).format(value);

  static String decimal(BuildContext context, num value, {int digits = 1}) =>
      NumberFormat.decimalPatternDigits(
        locale: localeName(context),
        decimalDigits: digits,
      ).format(value);

  static String longDate(BuildContext context, DateTime value) =>
      DateFormat.yMMMMd(localeName(context)).format(value);

  static String shortDayMonth(BuildContext context, DateTime value) =>
      DateFormat.MMMd(localeName(context)).format(value);

  static String monthYear(BuildContext context, DateTime value) =>
      DateFormat.yMMMM(localeName(context)).format(value);

  static String shortWeekday(BuildContext context, DateTime value) =>
      DateFormat.E(localeName(context)).format(value);

  static String time(BuildContext context, DateTime value) =>
      DateFormat.jm(localeName(context)).format(value);
}
