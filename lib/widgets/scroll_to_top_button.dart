import 'package:flutter/material.dart';

import '../l10n/l10n_context.dart';

/// Shows a compact, circular shortcut after [controller] has moved far enough
/// from the beginning of its scroll extent.
class ScrollToTopButton extends StatefulWidget {
  final ScrollController controller;
  final double showAfter;
  final Duration scrollDuration;

  const ScrollToTopButton({
    super.key,
    required this.controller,
    this.showAfter = 200,
    this.scrollDuration = const Duration(milliseconds: 350),
  });

  @override
  State<ScrollToTopButton> createState() => _ScrollToTopButtonState();
}

class _ScrollToTopButtonState extends State<ScrollToTopButton> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant ScrollToTopButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_handleScroll);
    widget.controller.addListener(_handleScroll);
    _visible = false;
  }

  void _handleScroll() {
    final visible =
        widget.controller.hasClients &&
        widget.controller.offset > widget.showAfter;
    if (visible == _visible || !mounted) return;
    setState(() => _visible = visible);
  }

  Future<void> _scrollToTop() async {
    if (!widget.controller.hasClients) return;
    await widget.controller.animateTo(
      widget.controller.position.minScrollExtent,
      duration: widget.scrollDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return FloatingActionButton.small(
      heroTag: null,
      tooltip: context.l10n.scrollToTop,
      shape: const CircleBorder(),
      onPressed: _scrollToTop,
      child: const Icon(Icons.keyboard_arrow_up),
    );
  }
}
