import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/widgets/dpad_scope.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/services/github_update_service.dart';

Future<void> showUpdateDialog(
  BuildContext context, {
  GithubUpdateService? service,
}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(service: service ?? GithubUpdateService()),
    );

enum _UpdateState {
  checking,
  available,
  current,
  downloading,
  ready,
  installing,
  permission,
  error
}

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.service});
  final GithubUpdateService service;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  _UpdateState _state = _UpdateState.checking;
  UpdateRelease? _release;
  double _progress = 0;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _state = _UpdateState.checking;
      _release = null;
    });
    try {
      final release = await widget.service.check();
      if (!mounted) return;
      setState(() {
        _release = release;
        _state =
            release == null ? _UpdateState.current : _UpdateState.available;
      });
    } catch (error) {
      _failure(error);
    }
  }

  void _failure(Object error) {
    LoggerService.instance
        .warning('Échec de la mise à jour (${error.runtimeType})');
    if (!mounted) return;
    setState(() {
      _errorCode = switch (error) {
        UpdateException(:final code) => code,
        PlatformException(:final code) => code,
        _ => 'network',
      };
      _state = _UpdateState.error;
    });
  }

  Future<void> _download() async {
    final release = _release;
    if (release == null) return;
    setState(() {
      _progress = 0;
      _state = _UpdateState.downloading;
    });
    try {
      await widget.service.download(release, (progress) {
        if (mounted) setState(() => _progress = progress);
      });
      if (!mounted) return;
      setState(() => _state = _UpdateState.ready);
      await _install();
    } catch (error) {
      _failure(error);
    }
  }

  Future<void> _install() async {
    setState(() => _state = _UpdateState.installing);
    try {
      final launched = await widget.service.install(_release!);
      if (!mounted) return;
      if (launched) {
        Navigator.of(context).pop();
      } else {
        setState(() => _state = _UpdateState.permission);
      }
    } catch (error) {
      _failure(error);
    }
  }

  String _errorText(AppLocalizations l) => switch (_errorCode) {
        'no_release' => l.updateNoRelease,
        'missing_asset' || 'invalid_asset' => l.updateAssetError,
        'invalid_apk' => l.updateInvalidApk,
        'integrity' => l.updateIntegrityError,
        _ => l.updateGenericError,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final busy = _state == _UpdateState.checking ||
        _state == _UpdateState.downloading ||
        _state == _UpdateState.installing;
    final content = switch (_state) {
      _UpdateState.checking => Text(l.updateChecking),
      _UpdateState.current => Text(l.updateCurrent),
      _UpdateState.available => SingleChildScrollView(
          child: Text(
            '${l.updateAvailable}\n${_release!.version}'
            '${_release!.notes.trim().isEmpty ? '' : '\n\n${_release!.notes}'}',
          ),
        ),
      _UpdateState.downloading => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.updateDownloading),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress),
            Text('${(_progress * 100).floor()} %'),
          ],
        ),
      _UpdateState.ready => Text(l.updateReady),
      _UpdateState.installing => Text(l.updateReady),
      _UpdateState.permission => Text(l.updatePermission),
      _UpdateState.error => Text(_errorText(l)),
    };
    return PopScope(
      canPop: !busy,
      child: DpadScope(
        child: AlertDialog(
          title: Text(l.updateTitle),
          content: SizedBox(width: 520, child: content),
          actions: [
            if (!busy)
              TextButton(
                autofocus: true,
                onPressed: () => Navigator.pop(context),
                child: Text(l.updateLater),
              ),
            if (_state == _UpdateState.available)
              FilledButton(onPressed: _download, child: Text(l.updateInstall)),
            if (_state == _UpdateState.ready ||
                _state == _UpdateState.permission)
              FilledButton(
                  onPressed: _install, child: Text(l.updateRetryInstall)),
            if (_state == _UpdateState.error)
              FilledButton(onPressed: _check, child: Text(l.updateRetry)),
          ],
        ),
      ),
    );
  }
}
