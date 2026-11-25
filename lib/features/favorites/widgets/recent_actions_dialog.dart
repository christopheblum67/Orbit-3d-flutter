import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_watch_style_button.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';

enum _RecentAction { favorite, remove }

Future<void> showRecentActions(
  BuildContext context,
  WidgetRef ref,
  FavoriteEntry entry,
) async {
  final profileId = ref.read(currentProfileProvider)?.id;
  final subscriptionId = ref.read(activeSubscriptionProvider)?.id;
  final heldKeys = HardwareKeyboard.instance.logicalKeysPressed.intersection({
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.gameButtonA,
  });
  KeyEventResult blockHeldKey(KeyEvent event) {
    if (!heldKeys.contains(event.logicalKey)) return KeyEventResult.ignored;
    if (event is KeyUpEvent) heldKeys.remove(event.logicalKey);
    return KeyEventResult.handled;
  }

  if (heldKeys.isNotEmpty) {
    FocusManager.instance.addEarlyKeyEventHandler(blockHeldKey);
  }
  _RecentAction? action;
  try {
    action = await showDialog<_RecentAction>(
      context: context,
      builder: (_) => _RecentActionsDialog(title: entry.title),
    );
  } finally {
    FocusManager.instance.removeEarlyKeyEventHandler(blockHeldKey);
  }
  if (action == null || !context.mounted) return;
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (profileId == null || ref.read(currentProfileProvider)?.id != profileId) {
    messenger.showSnackBar(SnackBar(content: Text(l.episodeProfileChanged)));
    return;
  }
  if (action == _RecentAction.favorite &&
      ref.read(activeSubscriptionProvider)?.id != subscriptionId) {
    messenger.showSnackBar(
      SnackBar(content: Text(l.recommendationSubscriptionChanged)),
    );
    return;
  }

  try {
    if (action == _RecentAction.favorite) {
      await ref.read(favoritesProvider.notifier).add(entry);
      if (context.mounted &&
          ref.read(currentProfileProvider)?.id == profileId &&
          ref.read(activeSubscriptionProvider)?.id == subscriptionId) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.addedToFavorites(entry.title))),
        );
      }
    } else {
      await ref
          .read(recentlyWatchedProvider.notifier)
          .remove(entry.type, entry.id);
    }
  } on FavoriteScopeRequired {
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l.favoritesNeedScope)));
    }
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        context: ErrorDescription('while updating recent content'),
      ),
    );
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(userFriendlyError(error))));
    }
  }
}

class _RecentActionsDialog extends StatefulWidget {
  const _RecentActionsDialog({required this.title});

  final String title;

  @override
  State<_RecentActionsDialog> createState() => _RecentActionsDialogState();
}

class _RecentActionsDialogState extends State<_RecentActionsDialog> {
  final _nodes = [FocusNode(), FocusNode()];

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = [l.favoritesAdd, l.recentRemove];
    final icons = [Icons.favorite_border, Icons.visibility_off_outlined];
    return AlertDialog(
      title: Text(widget.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      content: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
            return KeyEventResult.ignored;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
              _nodes[0].hasFocus) {
            _nodes[1].requestFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
              _nodes[1].hasFocus) {
            _nodes[0].requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < labels.length; index++) ...[
                  if (index > 0) const SizedBox(height: 20),
                  TvWatchStyleButton(
                    focusNode: _nodes[index],
                    autofocus: index == 1,
                    icon: icons[index],
                    label: labels[index],
                    onPressed: () =>
                        Navigator.pop(context, _RecentAction.values[index]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
