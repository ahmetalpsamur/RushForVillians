import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/title_catalog.dart';
import '../../l10n/content_localizations.dart';
import '../../l10n/l10n_context.dart';
import '../../models/mail_message.dart';
import '../../widgets/section_card.dart';

/// Posta kutusu (Bölüm D / Faz 3).
///
/// Ekran **veri tutmaz**: gösterilecek postalar ve "alındı mı" bilgisi
/// `RootShell`'den geliyor, alma işlemi callback ile ona dönüyor. GD27'nin
/// aynı deseni — itilen bir ekran kendi kopyasını tutarsa iki doğruluk
/// kaynağı oluşur.
///
/// Kod girişi **buraya** kondu: kodun karşılığı zaten bir posta, yani
/// oyuncu kodu girdiği yerle ödülü aldığı yer aynı ekran. Ayrı bir ekran
/// olsaydı "kodu girdim, ödül nerede" sorusu doğardı.
class MailboxScreen extends StatefulWidget {
  /// Oyuncunun görebileceği postalar, yeniden eskiye.
  final List<MailMessage> messages;

  /// Ödülü alınmış posta kimlikleri.
  final Set<String> claimedIds;

  /// Postanın ödülünü al. `RootShell` iki kez almayı kendisi engelliyor.
  final ValueChanged<MailMessage> onClaim;

  /// Postayı okundu işaretle.
  final ValueChanged<MailMessage> onRead;

  /// Kod dener; sonucu döner.
  final CodeRedemptionResult Function(String code) onRedeemCode;

  const MailboxScreen({
    super.key,
    required this.messages,
    required this.claimedIds,
    required this.onClaim,
    required this.onRead,
    required this.onRedeemCode,
  });

  @override
  State<MailboxScreen> createState() => _MailboxScreenState();
}

class _MailboxScreenState extends State<MailboxScreen> {
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submitCode() {
    final result = widget.onRedeemCode(_code.text);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        key: const ValueKey('code-result-notice'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result == CodeRedemptionResult.success
            ? AppColors.surface
            : AppColors.hp,
        content: Text(context.l10n.codeResultMessage(result)),
      ),
    );
    if (result == CodeRedemptionResult.success) _code.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mailboxTitle)),
      body: ListView(
        key: const ValueKey('mailbox-list'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.codeEntryTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('code-input'),
                        controller: _code,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: l10n.codeEntryHint,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _submitCode(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      key: const ValueKey('code-submit'),
                      onPressed: _submitCode,
                      child: Text(l10n.codeEntrySubmit),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (widget.messages.isEmpty)
            SectionCard(
              child: Text(
                l10n.mailboxEmpty,
                key: const ValueKey('mailbox-empty'),
                style: const TextStyle(color: Colors.white70),
              ),
            )
          else
            for (final mail in widget.messages) ...[
              _MailCard(
                mail: mail,
                claimed: widget.claimedIds.contains(mail.id),
                onClaim: () => widget.onClaim(mail),
                onRead: () => widget.onRead(mail),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _MailCard extends StatelessWidget {
  final MailMessage mail;
  final bool claimed;
  final VoidCallback onClaim;
  final VoidCallback onRead;

  const _MailCard({
    required this.mail,
    required this.claimed,
    required this.onClaim,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Açılan posta okundu sayılır. Çizim sırasında state değiştirmemek için
    // frame sonuna bırakılıyor.
    WidgetsBinding.instance.addPostFrameCallback((_) => onRead());

    final rewardLines = <String>[
      if (mail.reward.coins > 0) l10n.mailRewardCoins(mail.reward.coins),
      if (mail.reward.wheelSpins > 0)
        l10n.mailRewardSpins(mail.reward.wheelSpins),
      if (TitleCatalog.byId(mail.reward.titleId) case final title?)
        l10n.mailRewardTitle(l10n.titleName(title)),
    ];

    return SectionCard(
      key: ValueKey('mail-${mail.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                mail.kind == MailKind.reward
                    ? Icons.card_giftcard
                    : Icons.campaign,
                color: claimed ? Colors.white38 : AppColors.streak,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.mailTitle(mail.id),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.mailBody(mail.id),
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          if (rewardLines.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final line in rewardLines)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.streak.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.streak.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: AppColors.streak,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: claimed
                  ? OutlinedButton.icon(
                      key: ValueKey('mail-claimed-${mail.id}'),
                      onPressed: null,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(l10n.mailClaimed),
                    )
                  : FilledButton.icon(
                      key: ValueKey('mail-claim-${mail.id}'),
                      onPressed: onClaim,
                      icon: const Icon(Icons.redeem, size: 18),
                      label: Text(l10n.mailClaim),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
