import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/media_action_button.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

class MoviePlaybackActions extends StatelessWidget {
  const MoviePlaybackActions({
    super.key,
    required this.onStart,
    required this.onResume,
    this.onTrailer,
  });

  final VoidCallback onStart;
  final VoidCallback? onResume;
  final VoidCallback? onTrailer;

  @override
  Widget build(BuildContext context) {
    final isTvLayout = MediaQuery.sizeOf(context).width >= 900;
    return FocusTraversalGroup(
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            MediaActionButton(
              autofocus: onResume == null,
              onPressed: onStart,
              icon: Icons.play_arrow_rounded,
              label: AppLocalizations.of(context).start,
              isTvLayout: isTvLayout,
            ),
            MediaActionButton(
              autofocus: onResume != null,
              onPressed: onResume,
              icon: Icons.replay_rounded,
              label: AppLocalizations.of(context).resumeAction,
              isTvLayout: isTvLayout,
            ),
            if (onTrailer != null)
              MediaActionButton(
                onPressed: onTrailer,
                icon: Icons.play_circle_outline,
                label: 'Bande-annonce',
                isTvLayout: isTvLayout,
              ),
          ],
        ),
      ),
    );
  }
}
