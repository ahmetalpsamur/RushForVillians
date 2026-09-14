import 'package:flutter/material.dart';
import '../../core/constants/safety_messages.dart';
import '../../core/theme/app_theme.dart';
import '../../services/safety_notice_storage.dart';
import '../../widgets/section_card.dart';

class SafetyScreen extends StatefulWidget {
  final VoidCallback? onAccepted;
  const SafetyScreen({super.key, this.onAccepted});
  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  bool _checked = false;
  bool _saving = false;
  bool _failed = false;

  Future<void> _accept() async {
    if (!_checked || _saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await SafetyNoticeStorage.accept();
      if (mounted) widget.onAccepted?.call();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = SafetyMessages.of(context);
    return PopScope(
      canPop: widget.onAccepted == null,
      child: Scaffold(
        appBar: AppBar(
          title: Text(copy.title),
          automaticallyImplyLeading: widget.onAccepted == null,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    child: Text(
                      copy.fullNotice,
                      style: const TextStyle(height: 1.6),
                    ),
                  ),
                  if (widget.onAccepted != null) ...[
                    CheckboxListTile(
                      value: _checked,
                      onChanged:
                          _saving
                              ? null
                              : (value) =>
                                  setState(() => _checked = value ?? false),
                      title: Text(copy.checkbox),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (_failed)
                      Text(
                        copy.saveError,
                        style: const TextStyle(color: AppColors.accent),
                      ),
                    FilledButton(
                      onPressed: _checked && !_saving ? _accept : null,
                      child: Text(copy.continueLabel),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> showSafetyReminder(
  BuildContext context, {
  bool battle = false,
}) async {
  final copy = SafetyMessages.of(context);
  var acknowledged = false;
  return await showDialog<bool>(
        context: context,
        builder:
            (context) => StatefulBuilder(
              builder:
                  (context, setModalState) => AlertDialog(
                    title: Text(copy.firstSafety),
                    scrollable: true,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(battle ? copy.battleNotice : copy.adventureNotice),
                        if (!battle) ...[
                          const SizedBox(height: 16),
                          CheckboxListTile(
                            key: const ValueKey(
                              'walking-safety-acknowledgement',
                            ),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: acknowledged,
                            onChanged:
                                (value) => setModalState(
                                  () => acknowledged = value ?? false,
                                ),
                            title: Text(
                              copy.walkingAcknowledgement,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(copy.later),
                      ),
                      FilledButton(
                        onPressed:
                            battle || acknowledged
                                ? () => Navigator.pop(context, true)
                                : null,
                        child: Text(
                          battle ? copy.startBattle : copy.startAdventure,
                        ),
                      ),
                    ],
                  ),
            ),
      ) ??
      false;
}
