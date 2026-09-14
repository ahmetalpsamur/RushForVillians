import 'package:flutter/widgets.dart';
import '../../l10n/l10n_context.dart';

/// All safety copy and the independently versioned device notice.
class SafetyMessages {
  static const noticeVersion = 1;
  final bool tr;
  const SafetyMessages({this.tr = true});
  factory SafetyMessages.of(BuildContext context) =>
      SafetyMessages(tr: context.l10n.localeName == 'tr');
  String get title => tr ? 'Güvenlik Uyarısı' : 'Safety Warning';
  String get pageTitle => tr ? 'Güvenlik' : 'Safety';
  String get fullNotice =>
      tr
          ? 'Rush for Villains fiziksel aktivite ile birlikte kullanılan bir oyundur.\n\nUygulamayı kullanırken çevrenize, trafik koşullarına, araçlara, yayalara ve çevrenizdeki engellere dikkat edin.\n\nAraç kullanırken veya güvenli şekilde ekranla etkileşime geçemeyeceğiniz durumlarda uygulamayı kullanmayın.\n\nÖzel mülklere, erişimi yasak alanlara veya tehlikeli bölgelere oyun amacıyla girmeyin.\n\nOyun ekranıyla etkileşime geçmeden önce güvenli bir yerde olduğunuzdan emin olun.'
          : 'Rush for Villains is a game used with physical activity.\n\nPay attention to your surroundings, traffic, vehicles, pedestrians and obstacles.\n\nDo not use the app while driving or when you cannot safely interact with the screen.\n\nDo not enter private property, restricted areas or dangerous places to play.\n\nMake sure you are in a safe place before interacting with the game.';
  String get checkbox =>
      tr
          ? 'Güvenlik uyarısını okudum ve anladım.'
          : 'I have read and understood the safety warning.';
  String get continueLabel => tr ? 'Devam Et' : 'Continue';
  String get saveError =>
      tr
          ? 'Onay kaydedilemedi. Lütfen tekrar dene.'
          : 'Could not save your acknowledgement. Please try again.';
  String get firstSafety => tr ? '⚠️ Önce Güvenlik' : '⚠️ Safety First';
  String get adventureNotice =>
      tr
          ? 'Çevrene ve trafiğe dikkat et.\nHareket halindeyken veya araç kullanırken ekranla etkileşime geçme.\nCanavarların ve ödüllerin seni bekleyecek.'
          : 'Pay attention to your surroundings and traffic.\nDo not interact with the screen while moving or driving.\nYour monsters and rewards will wait.';
  String get walkingAcknowledgement =>
      tr
          ? 'Yürürken telefonla ilgilenmeyeceğimi onaylıyorum.'
          : 'I agree not to use my phone while walking.';
  String get startAdventure =>
      tr ? 'Güvendeyim, Maceraya Başla' : 'I’m safe, start adventure';
  String get battleNotice =>
      tr
          ? 'Çevreni kontrol et. Güvenli olduğunda savaşa başla.'
          : 'Check your surroundings. Start the battle when you are safe.';
  String get startBattle => tr ? 'Savaşa Başla' : 'Start Battle';
  String get later => tr ? 'Daha Sonra' : 'Later';
  String get walking =>
      tr
          ? 'Önce yürü, sonra güvenle savaş. Süre sınırı yok; telefonunu cebinde tutabilirsin.'
          : 'Walk first, fight safely later. There is no time limit; you can keep your phone in your pocket.';
  String get noTimeLimit => tr ? 'Süre sınırı yok' : 'No time limit';
  String get ready =>
      tr
          ? 'Adım hedefin tamamlandı. Canavar seni bekliyor; güvenli olduğunda savaşabilirsin.'
          : 'Step target complete. Your monster will wait; fight when you are safe.';
}
