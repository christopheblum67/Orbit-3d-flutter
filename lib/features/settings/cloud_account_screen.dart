import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/features/settings/cloud_profile_recovery_screen.dart';
import 'package:orbit_3d_flutter/features/settings/tv_pairing_screen.dart';
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
  bool _busy = false;
  bool? _isTv = qrPairingAvailable ? null : false;

  @override
  void initState() {
    super.initState();
    try {
      _service = widget.service ?? CloudAccountService();
    } on FirebaseException {
      _error = 'Firebase n’est pas disponible sur cet appareil.';
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
        setState(() {
          _error = switch (error.code) {
            GoogleSignInExceptionCode.canceled =>
              'Connexion Google annulée ou impossible. Si le problème persiste, '
                  'vérifiez la configuration Google de cette application.',
            GoogleSignInExceptionCode.clientConfigurationError =>
              'Configuration Google incorrecte : vérifiez le client OAuth et '
                  'la signature de cette application.',
            _ => 'Connexion Google impossible sur cet appareil.',
          };
        });
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authError(error.code));
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _error = _authError(error.code));
    } on PlatformException {
      if (mounted) {
        setState(() =>
            _error = 'Service de connexion indisponible sur cet appareil.');
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() =>
            _error = 'Service de connexion indisponible sur cet appareil.');
      }
    } on UnsupportedError {
      if (mounted) {
        setState(
            () => _error = 'Connexion Google indisponible sur cet appareil.');
      }
    } on StateError {
      if (mounted) {
        setState(() => _error = 'Connexion impossible. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _authError(String code) {
    return switch (code) {
      'invalid-email' => 'Adresse e-mail invalide.',
      'weak-password' => 'Le mot de passe est trop faible.',
      'email-already-in-use' => 'Cette adresse est déjà utilisée.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' =>
        'Adresse e-mail ou mot de passe incorrect.',
      'network-request-failed' => 'Connexion réseau indisponible.',
      'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
      'operation-not-allowed' =>
        'Cette méthode de connexion n’est pas activée.',
      'provider-already-linked' => 'Ce compte est déjà lié à Google.',
      'credential-already-in-use' ||
      'account-exists-with-different-credential' =>
        'Ce compte Google est déjà associé à un autre compte Firebase. '
            'Aucun compte ni donnée n’a été fusionné. Pour utiliser cet autre '
            'compte, déconnectez-vous puis connectez-vous avec Google.',
      _ =>
        'Connexion impossible. Réessayez ou vérifiez la configuration Firebase.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    return Scaffold(
      appBar: AppBar(title: const Text('Compte cloud')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Après connexion, retrouvez vos profils et activez la '
            'synchronisation chiffrée du profil actif, de son activité, '
            'des préférences et des abonnements.',
          ),
          const SizedBox(height: 8),
          if (_isTv == false)
            const Text(
              'Si un compte est déjà connecté, Google lui sera lié sans changer '
              'son identifiant. Les comptes distincts ne sont pas fusionnés.',
            ),
          const SizedBox(height: 16),
          if (service != null)
            StreamBuilder<User?>(
              stream: service.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Impossible de lire l’état du compte.');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Vérification du compte…');
                }
                if (!snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Aucun compte cloud connecté.'),
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
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Compte associé, mais le nettoyage de la session temporaire a échoué.'),
                                    ));
                                  }
                                  await Navigator.of(context)
                                      .push(MaterialPageRoute<void>(
                                    builder: (_) => CloudProfileRecoveryScreen(
                                        initialPhrase: result.phrase),
                                  ));
                                },
                          child: const Text('Associer cette TV par QR code'),
                        ),
                    ],
                  );
                }
                if (snapshot.data!.isAnonymous) {
                  return const Text(
                      'Compte temporaire connecté sur cet appareil.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Compte connecté : ${snapshot.data!.email ?? 'Google'}'),
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
                      child:
                          const Text('Configurer la synchronisation chiffrée'),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Adresse e-mail'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
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
                child: const Text('Se connecter'),
              ),
              OutlinedButton(
                onPressed: service == null || _busy
                    ? null
                    : () => _run(() async {
                          await service.registerWithEmail(
                              _email.text, _password.text);
                          _password.clear();
                        }),
                child: const Text('Créer un compte'),
              ),
              OutlinedButton(
                onPressed: service == null || _busy
                    ? null
                    : () => _run(() async {
                          await service.sendPasswordReset(_email.text);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Si le compte existe, un e-mail de réinitialisation peut être envoyé.')),
                            );
                          }
                        }),
                child: const Text('Mot de passe oublié'),
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
                            ? 'Compte Google déjà lié'
                            : user == null
                                ? 'Se connecter avec Google'
                                : 'Lier un compte Google',
                      ),
                    );
                  },
                ),
              TextButton(
                onPressed: service == null || _busy
                    ? null
                    : () => _run(service.signOut),
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
