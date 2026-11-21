import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';

/// Champ de recherche compact, utilisable à la télécommande.
///
/// En mode D-pad, le champ reste en lecture seule tant que l'utilisateur
/// n'a pas appuyé sur OK : le clavier à l'écran ne capte donc pas les
/// flèches et la navigation peut le quitter dans les quatre directions.
class DpadSearchField extends ConsumerStatefulWidget {
  const DpadSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.autofocus = false,
    this.onNavigateDown,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final VoidCallback? onNavigateDown;

  @override
  ConsumerState<DpadSearchField> createState() => _DpadSearchFieldState();
}

class _DpadSearchFieldState extends ConsumerState<DpadSearchField> {
  final FocusNode _focus = FocusNode();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _focus.onKeyEvent = _onKey;
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus && _editing) setState(() => _editing = false);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!ref.read(tvModeNotifierProvider).enabled)
      return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (!_editing) {
      if (key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.gameButtonA) {
        _startEditing();
        return KeyEventResult.handled;
      }
      final direction = switch (key) {
        LogicalKeyboardKey.arrowUp => TraversalDirection.up,
        LogicalKeyboardKey.arrowDown => TraversalDirection.down,
        LogicalKeyboardKey.arrowLeft => TraversalDirection.left,
        LogicalKeyboardKey.arrowRight => TraversalDirection.right,
        _ => null,
      };
      if (direction != null) {
        if (direction == TraversalDirection.down &&
            widget.onNavigateDown != null) {
          widget.onNavigateDown!();
        } else {
          node.focusInDirection(direction);
        }
        return KeyEventResult.handled;
      }
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      setState(() => _editing = false);
      if (key == LogicalKeyboardKey.arrowDown &&
          widget.onNavigateDown != null) {
        widget.onNavigateDown!();
      } else {
        node.focusInDirection(
          key == LogicalKeyboardKey.arrowDown
              ? TraversalDirection.down
              : TraversalDirection.up,
        );
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _startEditing() {
    if (_editing) return;
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing && _focus.hasFocus) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: ref.read(tvModeNotifierProvider),
      builder: (context, _) {
        final dpad = ref.read(tvModeNotifierProvider).enabled;
        return TextField(
          controller: widget.controller,
          focusNode: _focus,
          autofocus: widget.autofocus,
          readOnly: dpad && !_editing,
          onChanged: widget.onChanged,
          onTap: () {
            _startEditing();
          },
          onEditingComplete: () {
            setState(() => _editing = false);
            FocusScope.of(context).nextFocus();
          },
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
            ),
            prefixIcon: const Icon(Icons.search, size: 20),
            prefixIconColor: WidgetStateColor.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            ),
            isDense: true,
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        );
      },
    );
  }
}
