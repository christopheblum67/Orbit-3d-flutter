import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/widgets/dpad_scope.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

const _contactAddress = 'alsaceiptv@gmail.com';

class ReadmeContactDialog extends StatefulWidget {
  const ReadmeContactDialog({super.key, required this.onLegal});

  final VoidCallback onLegal;

  @override
  State<ReadmeContactDialog> createState() => _ReadmeContactDialogState();
}

class _ReadmeContactDialogState extends State<ReadmeContactDialog> {
  final _email = Uri(scheme: 'mailto', path: _contactAddress);
  late final Future<bool> _emailAvailable = canLaunchUrl(_email);
  bool _launchFailed = false;

  Future<void> _openEmail() async {
    try {
      if (await launchUrl(_email, mode: LaunchMode.externalApplication)) return;
      LoggerService.instance.warning('No email application could be opened');
    } on PlatformException catch (error, stack) {
      LoggerService.instance.error(
        'Unable to open the email application',
        error: error,
        stackTrace: stack,
      );
    }
    if (mounted) {
      setState(() => _launchFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return DpadScope(
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/icons/orbit_icon_dark.jpg',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l.contactTeamTitle)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.contactTeamIntro),
                const SizedBox(height: 16),
                Text(l.contactAddress,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const SelectableText(_contactAddress),
                const SizedBox(height: 16),
                Text(l.contactImportant,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: scheme.primary)),
                const SizedBox(height: 4),
                Text(l.contactTeamWarning),
                FutureBuilder<bool>(
                  future: _emailAvailable,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      LoggerService.instance.error(
                        'Unable to detect an email application',
                        error: snapshot.error,
                        stackTrace: snapshot.stackTrace,
                      );
                    }
                    if (_launchFailed ||
                        (snapshot.connectionState == ConnectionState.done &&
                            snapshot.data != true)) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(l.contactMailUnavailable,
                            style: Theme.of(context).textTheme.bodySmall),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: widget.onLegal,
            child: Text(l.contactLegal),
          ),
          FutureBuilder<bool>(
            future: _emailAvailable,
            builder: (context, snapshot) => snapshot.data == true
                ? FilledButton.icon(
                    onPressed: _openEmail,
                    icon: const Icon(Icons.email_outlined),
                    label: Text(l.contactCompose),
                  )
                : const SizedBox.shrink(),
          ),
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }
}
