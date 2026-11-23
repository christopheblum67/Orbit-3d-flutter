import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/core/widgets/dpad_scope.dart';
import 'package:orbit_3d_flutter/features/settings/cloud_profile_recovery_screen.dart';
import 'package:orbit_3d_flutter/features/settings/tv_pairing_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_pairing_service.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_account_service.dart';

class CloudAccountScreen extends StatefulWidget {
  const CloudAccountScreen({super.key, this.service, this.tvDetector});

  final CloudAccountService? service;
  @visibleForTesting
  final Future<bool> Function()? tvDetector;

  @override
  State<CloudAccountScreen> createState() => _CloudAccountScreenState();
}

class _CloudAccountScreenState extends State<CloudAccountScreen> {
  static final _focusedButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.focused) ? const Color(0xFFFFC107) : null,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.focused) ? Colors.black : null,
    ),
  );

  final _email = TextEditingController();
  final _password = TextEditingController();
  CloudAccountService? _service;
  String? _error;
  bool _firebaseUnavailable = false;
  bool _busy = false;
  bool? _isTv = qrPairingAvailable ? null : false;

  @override
  void initState() {
    super.initState();
    try {
      _service = widget.service ?? CloudAccountService();
    } on FirebaseException {
      _firebaseUnavailable = true;
    }
    if (qrPairingAvailable) _detectTv();
  }

  Future<void> _detectTv() async {
    try {
      final isTv =
          await (widget.tvDetector?.call() ?? HardwareDetectorService.isTv());
      if (mounted) setState(() => _isTv = isTv);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          context: ErrorDescription('while detecting the TV for cloud pairing'),
        ),
      );
      if (mounted) setState(() => _isTv = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on GoogleSignInException catch (error) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        setState(() {
          _error = switch (error.code) {
            GoogleSignInExceptionCode.canceled => l.cloudGoogleCanceled,
            GoogleSignInExceptionCode.clientConfigurationError =>
              l.cloudGoogleConfiguration,
            _ => l.cloudGoogleUnavailable,
          };
        });
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authError(error.code));
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _error = _authError(error.code));
    } on PlatformException {
      if (mounted) {
        setState(
            () => _error = AppLocalizations.of(context).cloudSignInUnavailable);
      }
    } on MissingPluginException {
      if (mounted) {
        setState(
            () => _error = AppLocalizations.of(context).cloudSignInUnavailable);
      }
    } on UnsupportedError {
      if (mounted) {
        setState(
            () => _error = AppLocalizations.of(context).cloudGoogleUnavailable);
      }
    } on StateError {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).cloudSignInRetry);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _authError(String code) {
    final l = AppLocalizations.of(context);
    return switch (code) {
      'invalid-email' => l.cloudInvalidEmail,
      'weak-password' => l.cloudWeakPassword,
      'email-already-in-use' => l.cloudEmailInUse,
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' =>
        l.cloudInvalidCredentials,
      'network-request-failed' => l.cloudNetworkUnavailable,
      'too-many-requests' => l.cloudTooManyAttempts,
      'operation-not-allowed' => l.cloudMethodDisabled,
      'provider-already-linked' => l.cloudGoogleAlreadyLinked,
      'credential-already-in-use' ||
      'account-exists-with-different-credential' =>
        l.cloudGoogleOtherAccount,
      _ => l.cloudFirebaseSignInFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsCloudAccount)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l.cloudAccountIntro),
          const SizedBox(height: 8),
          if (_isTv == false) Text(l.cloudAccountLinkHelp),
          const SizedBox(height: 16),
          if (service != null)
            StreamBuilder<User?>(
              stream: service.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(l.cloudAccountStateError);
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text(l.cloudAccountChecking);
                }
                if (!snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.cloudAccountNone),
                      if (qrPairingAvailable)
                        TextButton(
                          autofocus: true,
                          style: _focusedButtonStyle,
                          onPressed: _busy
                              ? null
                              : () async {
                                  final result = await Navigator.of(context)
                                      .push<PairingResult>(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const TvPairingScreen()),
                                  );
                                  if (!context.mounted || result == null)
                                    return;
                                  if (result.cleanupFailed) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content:
                                          Text(l.cloudPairingCleanupFailed),
                                    ));
                                  }
                                  await Navigator.of(context)
                                      .push(MaterialPageRoute<void>(
                                    builder: (_) => CloudProfileRecoveryScreen(
                                      initialPhrase: result.phrase,
                                      initialProfileIds: result.profileIds,
                                    ),
                                  ));
                                },
                          child: Text(l.cloudPairTv),
                        ),
                    ],
                  );
                }
                if (snapshot.data!.isAnonymous) {
                  return Text(l.cloudTemporaryAccount);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.cloudAccountConnected(
                        snapshot.data!.email ?? 'Google')),
                    TextButton(
                      autofocus: true,
                      style: _focusedButtonStyle,
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const CloudProfileRecoveryScreen(),
                                ),
                              ),
                      child: Text(l.cloudRecoverProfiles),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 16),
          DpadScope(
            child: TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(labelText: l.cloudEmail),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: l.subscriptionPassword),
          ),
          if (_error != null || _firebaseUnavailable) ...[
            const SizedBox(height: 12),
            Text(_error ?? l.cloudFirebaseUnavailable,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: service == null || _busy
                    ? null
                    : () => _run(() async {
                          await service.signInWithEmail(
                              _email.text, _password.text);
                          _password.clear();
                        }),
                child: Text(l.cloudSignIn),
              ),
              OutlinedButton(
                onPressed: service == null || _busy
                    ? null
                    : () => _run(() async {
                          await service.registerWithEmail(
                              _email.text, _password.text);
                          _password.clear();
                        }),
                child: Text(l.cloudCreateAccount),
              ),
              OutlinedButton(
                onPressed: service == null || _busy
                    ? null
                    : () => _run(() async {
                          await service.sendPasswordReset(_email.text);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.cloudResetEmailSent)),
                            );
                          }
                        }),
                child: Text(l.cloudForgotPassword),
              ),
              if (service != null && _isTv == false)
                StreamBuilder<User?>(
                  stream: service.authStateChanges,
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final linked = user?.providerData.any(
                          (provider) => provider.providerId == 'google.com',
                        ) ??
                        false;
                    return OutlinedButton(
                      onPressed: _busy || linked || snapshot.hasError
                          ? null
                          : () => _run(() async => service.signInWithGoogle()),
                      child: Text(
                        linked
                            ? l.cloudGoogleLinked
                            : user == null
                                ? l.cloudSignInWithGoogle
                                : l.cloudLinkGoogle,
                      ),
                    );
                  },
                ),
              TextButton(
                onPressed: service == null || _busy
                    ? null
                    : () => _run(service.signOut),
                child: Text(l.cloudSignOut),
              ),
            ],
          ),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          Text(l.cloudSyncProfileHelp),
        ],
      ),
    );
  }
}
