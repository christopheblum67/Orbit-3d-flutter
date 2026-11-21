import 'dart:async';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_pairing_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TvPairingScreen extends StatefulWidget {
  const TvPairingScreen({super.key});

  @override
  State<TvPairingScreen> createState() => _TvPairingScreenState();
}

class _TvPairingScreenState extends State<TvPairingScreen> {
  FirebaseApp? _temporaryApp;
  FirebaseAuth? _temporaryAuth;
  CloudPairingService? _service;
  TvPairingSession? _session;
  Timer? _timer;
  bool _busy = false;
  bool _checking = false;
  String? _account;
  String? _error;

  Future<void> _start() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        throw StateError(l.pairSignOutFirst);
      }
      final name =
          'orbit-pair-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
      final app = await Firebase.initializeApp(
        name: name,
        options: Firebase.app().options,
      );
      _temporaryApp = app;
      await CloudPairingService.prepareAppCheck(app: app);
      final auth = FirebaseAuth.instanceFor(app: app);
      _temporaryAuth = auth;
      final user = (await auth.signInAnonymously()).user;
      if (user == null || !user.isAnonymous) {
        throw StateError(l.pairTemporaryUnavailable);
      }
      final service = CloudPairingService(
        auth: auth,
        functions:
            FirebaseFunctions.instanceFor(app: app, region: qrPairingRegion),
      );
      _service = service;
      final session = await service.create(user.uid);
      _session = session;
      if (!mounted) {
        await _cleanUp(cancel: true);
        return;
      }
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
    } catch (error) {
      try {
        await _cleanUp(cancel: true);
        if (mounted) _error = _message(error);
      } catch (_) {
        if (mounted) {
          _error =
              '${_message(error)} ${l.pairCleanupIncomplete}';
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object error) {
    if (error is StateError) return error.message.toString();
    return AppLocalizations.of(context).pairUnavailable;
  }

  Future<void> _check() async {
    final session = _session;
    final service = _service;
    if (!mounted ||
        _checking ||
        session == null ||
        service == null ||
        _account != null) {
      return;
    }
    _checking = true;
    try {
      final account = await service.check(session);
      if (!mounted || !identical(_session, session)) return;
      if (account != null) {
        _timer?.cancel();
        setState(() => _account = account);
      }
    } catch (error) {
      _timer?.cancel();
      if (mounted) setState(() => _error = _message(error));
    } finally {
      _checking = false;
    }
  }

  Future<void> _confirm() async {
    final session = _session;
    final service = _service;
    if (_busy || session == null || service == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await service.consume(session, FirebaseAuth.instance);
      _session = null;
      var cleanupFailed = false;
      try {
        await _cleanUp(cancel: false);
      } catch (_) {
        cleanupFailed = true;
      }
      if (mounted) {
        Navigator.of(context).pop(
          PairingResult(
            result.uid,
            result.phrase,
            cleanupFailed: cleanupFailed,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error =
            '${_message(error)} ${AppLocalizations.of(context).pairRestart}');
      }
      try {
        await _cleanUp(cancel: true);
      } catch (_) {
        if (mounted) {
          setState(
            () => _error =
                '${_message(error)} ${AppLocalizations.of(context).pairCleanupIncomplete}',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cleanUp({required bool cancel}) async {
    _timer?.cancel();
    _timer = null;
    final session = _session;
    final service = _service;
    _session = null;
    try {
      if (cancel && session != null && service != null) {
        await service.cancel(session);
      }
    } finally {
      final auth = _temporaryAuth;
      final app = _temporaryApp;
      _temporaryAuth = null;
      _temporaryApp = null;
      _service = null;
      try {
        final user = auth?.currentUser;
        if (user != null && user.isAnonymous) await user.delete();
      } finally {
        try {
          if (auth != null) await auth.signOut();
        } finally {
          if (app != null) {
            CloudPairingService.forgetApp(app);
            await app.delete();
          }
        }
      }
    }
  }

  Future<void> _exit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _cleanUp(cancel: true);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppLocalizations.of(context).pairCleanupFailed;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_busy) {
      unawaited(
        _cleanUp(cancel: true).catchError((Object _) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception:
                  StateError('Nettoyage de la session temporaire impossible.'),
            ),
          );
        }),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_exit());
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l.pairTvTitle)),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l.pairInstructions),
            if (session == null && !_busy)
              FilledButton(
                autofocus: true,
                onPressed: _start,
                child: Text(l.pairCreateQr),
              ),
            if (session != null) ...[
              const SizedBox(height: 16),
              Center(
                child: ColoredBox(
                  color: Colors.white,
                  child:
                      QrImageView(data: session.invitation.qrValue, size: 260),
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                l.pairVerificationCode(session.invitation.verificationCode),
              ),
              Text(l.pairExpires),
              if (_account != null) ...[
                Text(l.pairAccount(_account!)),
                FilledButton(
                  onPressed: _busy ? null : _confirm,
                  child: Text(l.pairConfirmAccount),
                ),
              ] else
                Text(l.pairWaiting),
            ],
            if (_busy) const LinearProgressIndicator(),
            if (_error != null) Text(_error!),
            TextButton(
              onPressed: _busy ? null : _exit,
              child: Text(l.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
