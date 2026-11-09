import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_primary_button.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

class MoviePlaybackActions extends StatelessWidget {
  const MoviePlaybackActions({
    super.key,
    required this.onStart,
    required this.onResume,
  });

  final VoidCallback onStart;
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    final isTvLayout = MediaQuery.sizeOf(context).width >= 900;
    final minSize = isTvLayout ? const Size(220, 64) : null;
    final padding = isTvLayout
        ? const EdgeInsets.symmetric(vertical: 18, horizontal: 30)
        : const EdgeInsets.symmetric(vertical: 14, horizontal: 24);
    final textStyle = isTvLayout
        ? const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)
        : null;
    final iconSize = isTvLayout ? 30.0 : 24.0;
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: isTvLayout ? 40 : 16,
        runSpacing: isTvLayout ? 30 : 16,
        children: [
          TvPrimaryButton(
            autofocus: true,
            onPressed: onStart,
            minimumSize: minSize,
            padding: padding,
            icon: Icon(Icons.play_arrow_rounded, size: iconSize),
            label: Text(AppLocalizations.of(context).start, style: textStyle),
          ),
          if (isTvLayout)
            TvPrimaryButton(
              onPressed: onResume,
              minimumSize: minSize,
              padding: padding,
              icon: Icon(Icons.replay_rounded, size: iconSize),
              label: Text('Reprendre', style: textStyle),
            )
          else
            OutlinedButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Reprendre'),
              style: OutlinedButton.styleFrom(padding: padding),
            ),
        ],
      ),
    );
  }
}
