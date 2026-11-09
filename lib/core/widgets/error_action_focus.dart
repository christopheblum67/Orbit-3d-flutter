import 'package:flutter/material.dart';

/// Requests focus when an actionable blocking error appears.
class ErrorActionFocus extends StatefulWidget {
  const ErrorActionFocus({
    super.key,
    required this.autofocus,
    required this.builder,
  });

  final bool autofocus;
  final Widget Function(BuildContext context, FocusNode focusNode) builder;

  @override
  State<ErrorActionFocus> createState() => _ErrorActionFocusState();
}

class _ErrorActionFocusState extends State<ErrorActionFocus> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'ErrorAction');

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) _requestFocus();
  }

  @override
  void didUpdateWidget(covariant ErrorActionFocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autofocus && !oldWidget.autofocus) _requestFocus();
  }

  void _requestFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.autofocus) return;
      if (ModalRoute.of(context)?.isCurrent == false) return;
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _focusNode);
}
