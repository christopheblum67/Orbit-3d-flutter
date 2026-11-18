import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_pairing_service.dart';

class PairingScannerScreen extends StatefulWidget {
  const PairingScannerScreen({
    super.key,
    required this.phrase,
    required this.uid,
    this.profileIds = const {},
    this.profileNames = const [],
  });

  final String phrase;
  final String uid;
  final Set<String> profileIds;
  final List<String> profileNames;

  @override
  State<PairingScannerScreen> createState() => _PairingScannerScreenState();
}

class _PairingScannerScreenState extends State<PairingScannerScreen>
    with WidgetsBindingObserver {
  final _scanner = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  PairingInvitation? _invitation;
  bool _processing = false;
  bool _success = false;
  bool _accountChanged = false;
  String? _error;
  StreamSubscription<User?>? _authChanges;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authChanges = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        if (user == null || user.isAnonymous || user.uid != widget.uid) {
          if (mounted) {
            setState(() {
              _accountChanged = true;
              _error =
                  'Le compte cloud a changé. Fermez cet écran et recommencez.';
            });
          }
        }
      },
      onError: (Object _) {
        if (mounted) {
          setState(() {
            _accountChanged = true;
            _error = 'Impossible de vérifier le compte cloud.';
          });
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_invitation != null || _success) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_cameraAction(_scanner.stop));
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_cameraAction(_scanner.start));
    }
  }

  Future<void> _cameraAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible d’utiliser la caméra.');
    }
  }

  Future<void> _detected(BarcodeCapture capture) async {
    if (_processing || _invitation != null || _success) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    _processing = true;
    try {
      final invitation = PairingInvitation.parse(raw);
      await _scanner.stop();
      if (mounted) {
        setState(() {
          _invitation = invitation;
          _error = null;
        });
      }
    } on FormatException {
      if (mounted) {
        setState(
          () => _error = 'Ce QR code ne correspond pas à une session Orbit 3D.',
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible d’utiliser la caméra.');
    } finally {
      _processing = false;
    }
  }

  Future<void> _approve() async {
    final invitation = _invitation;
    if (_processing || _accountChanged || invitation == null) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous || user.uid != widget.uid) {
        throw StateError('Le compte cloud a changé.');
      }
      await CloudPairingService.prepareAppCheck();
      await CloudPairingService().approve(
        invitation,
        widget.phrase,
        widget.uid,
        profileIds: widget.profileIds,
      );
      if (mounted) {
        setState(() {
          _success = true;
          _invitation = null;
        });
      }
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message.toString());
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Association impossible. Vérifiez le réseau ou recréez le QR code sur la TV.',
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _rescan() {
    if (_processing) return;
    setState(() {
      _invitation = null;
      _error = null;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_authChanges?.cancel());
    unawaited(_scanner.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Associer une TV')),
        body: _success
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Demande envoyée. Confirmez le compte affiché sur la TV.',
                ),
              )
            : Column(
                children: [
                  if (_invitation == null)
                    Expanded(
                      child: MobileScanner(
                        controller: _scanner,
                        onDetect: _detected,
                        errorBuilder: (context, error) => const Center(
                          child: Text(
                            'Caméra indisponible. Autorisez son accès dans les réglages.',
                          ),
                        ),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Comparez ce code avec celui affiché sur la TV :',
                    ),
                    SelectableText(_invitation!.verificationCode),
                    const Text(
                      'N’acceptez que si les deux codes sont identiques et que vous contrôlez la TV.',
                    ),
                    if (widget.profileNames.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'La TV sélectionnera automatiquement : '
                          '${widget.profileNames.join(', ')}.',
                        ),
                      ),
                    FilledButton(
                      onPressed:
                          _processing || _accountChanged ? null : _approve,
                      child: const Text('Confirmer et associer'),
                    ),
                    TextButton(
                      onPressed: _processing ? null : _rescan,
                      child: const Text('Scanner à nouveau'),
                    ),
                  ],
                  if (_processing) const LinearProgressIndicator(),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!),
                    ),
                ],
              ),
      );
}
