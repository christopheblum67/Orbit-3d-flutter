import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/services/profile_pin.dart';

/// Contexte d'ouverture du pavé PIN.
enum PinPadMode {
  /// Saisie pour définir un nouveau code PIN (retourne `String?` via pop).
  set,

  /// Vérification d'un code PIN (retourne `bool?` via pop).
  verify,
}

/// Arguments passés via `extra` à la route `/profile/pin`.
class PinPadArgs {
  const PinPadArgs.set({this.confirmation = false})
      : mode = PinPadMode.set,
        profile = null;

  const PinPadArgs.verify(UserProfile this.profile)
      : mode = PinPadMode.verify,
        confirmation = false;

  final PinPadMode mode;
  final UserProfile? profile;
  final bool confirmation;

  bool get isVerify => mode == PinPadMode.verify;
}

/// Sprint 3 — pavé numérique TV :
/// - navigation au d-pad (flèches) entre les touches,
/// - retour haptique (selection sur focus, impact sur saisie),
/// - 4 chiffres, confirmation explicite pour la création,
/// - affichage des points ●.
class PinPadScreen extends ConsumerStatefulWidget {
  const PinPadScreen({super.key, required this.args});

  final PinPadArgs args;

  @override
  ConsumerState<PinPadScreen> createState() => _PinPadScreenState();
}

class _PinPadScreenState extends ConsumerState<PinPadScreen> {
  static const int _pinLength = 4;
  static const int _maxAttempts = 3;

  String _digits = '';
  int _attempts = 0;
  bool _wrong = false;
  bool _validated = false;
  bool _checking = false;
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _confirmFocus.dispose();
    super.dispose();
  }

  PinPadMode get _mode => widget.args.mode;

  String get _title =>
      _mode == PinPadMode.verify ? 'Code PIN requis' : 'Définir un code PIN';

  String get _subtitle {
    if (_mode == PinPadMode.verify) {
      final profile = widget.args.profile;
      final name = profile?.firstName.trim().isNotEmpty == true
          ? profile!.firstName.trim()
          : 'ce profil';
      return 'Entrez le code PIN de $name';
    }
    return widget.args.confirmation
        ? 'Confirmez votre code à 4 chiffres'
        : 'Choisissez un code à 4 chiffres';
  }

  void _append(String digit) {
    if (_checking || _digits.length >= _pinLength) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _digits += digit;
      _wrong = false;
    });
    if (_digits.length == _pinLength) {
      if (_mode == PinPadMode.verify) {
        _submit();
      } else {
        _confirmFocus.requestFocus();
      }
    }
  }

  void _erase() {
    if (_checking || _digits.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _onOk() {
    if (_checking || _digits.length != _pinLength) return;
    _submit();
  }

  Future<void> _submit() async {
    if (_checking || _validated) return;
    if (_mode == PinPadMode.set) {
      _finish(_digits);
      return;
    }
    setState(() => _checking = true);
    final profile = widget.args.profile;
    bool verified;
    try {
      verified = profile != null && await ProfilePin.verify(profile, _digits);
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        context: ErrorDescription('vérification du code PIN de profil'),
      ));
      if (!mounted) return;
      setState(() {
        _checking = false;
        _digits = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de vérifier le code PIN.')),
      );
      return;
    }
    if (!mounted) return;
    if (verified) {
      _finish(true);
      return;
    }
    _attempts++;
    HapticFeedback.vibrate();
    if (_attempts >= _maxAttempts) {
      _finish(false);
      return;
    }
    setState(() {
      _checking = false;
      _wrong = true;
      _digits = '';
    });
  }

  void _finish(Object? result) {
    if (_validated) return;
    _validated = true;
    context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.pinCode),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Annuler',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _title,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    _PinDots(filled: _digits.length, wrong: _wrong),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: _wrong
                          ? Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(
                                'Code incorrect — '
                                '${_maxAttempts - _attempts} essai(s) restant(s)',
                                style: TextStyle(
                                  color: scheme.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : const SizedBox(height: 40),
                    ),
                    const SizedBox(height: 20),
                    _buildKeyGrid(),
                    if (_mode == PinPadMode.set) ...[
                      const SizedBox(height: 12),
                      const Text(
                          'Après 4 chiffres, appuyez sur ✓ pour valider.',
                          textAlign: TextAlign.center),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildKeyRow(const ['1', '2', '3']),
        _buildKeyRow(const ['4', '5', '6']),
        _buildKeyRow(const ['7', '8', '9']),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PinKey(
                label: Icons.backspace_outlined,
                autofocus: false,
                onActivate: _erase,
              ),
              const SizedBox(width: 14),
              _PinKey(
                label: '0',
                autofocus: false,
                onActivate: () => _append('0'),
              ),
              const SizedBox(width: 14),
              _PinKey(
                label: Icons.check_rounded,
                autofocus: false,
                primary: true,
                focusNode: _confirmFocus,
                semanticsLabel: 'Valider le code PIN',
                onActivate: _onOk,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyRow(List<String> digits) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < digits.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            _PinKey(
              label: digits[i],
              autofocus: digits[i] == '1' && !_validated,
              onActivate: () => _append(digits[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _PinKey extends StatefulWidget {
  const _PinKey({
    required this.label,
    required this.onActivate,
    this.autofocus = false,
    this.primary = false,
    this.focusNode,
    this.semanticsLabel,
  });

  final Object label;
  final VoidCallback onActivate;
  final bool autofocus;
  final bool primary;
  final FocusNode? focusNode;
  final String? semanticsLabel;

  @override
  State<_PinKey> createState() => _PinKeyState();
}

class _PinKeyState extends State<_PinKey> {
  bool _focused = false;

  void _activate() {
    HapticFeedback.heavyImpact();
    widget.onActivate();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primaryColor = widget.primary ? scheme.tertiary : scheme.primary;
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        if (hasFocus) HapticFeedback.selectionClick();
        setState(() => _focused = hasFocus);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          _activate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        button: true,
        label: widget.semanticsLabel,
        child: GestureDetector(
          onTap: _activate,
          child: AnimatedScale(
            scale: _focused ? 1.08 : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _focused
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, Lighten.color(primaryColor)],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.surfaceContainerLow,
                          scheme.surfaceContainerHigh,
                        ],
                      ),
                border: Border.all(
                  color: _focused
                      ? primaryColor
                      : scheme.outlineVariant.withValues(alpha: 0.6),
                  width: _focused ? 2.5 : 1,
                ),
                boxShadow: [
                  if (_focused)
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.45),
                      blurRadius: 22,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: widget.label is IconData
                  ? Icon(
                      widget.label as IconData,
                      size: 34,
                      color: _focused ? scheme.onPrimary : scheme.onSurface,
                    )
                  : Text(
                      widget.label as String,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color:
                                _focused ? scheme.onPrimary : scheme.onSurface,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Points ● sanitaires du code PIN.
class _PinDots extends StatelessWidget {
  const _PinDots({required this.filled, required this.wrong});

  final int filled;
  final bool wrong;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: i < filled ? 22 : 18,
            height: i < filled ? 22 : 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: wrong
                  ? scheme.error
                  : i < filled
                      ? scheme.primary
                      : scheme.outlineVariant,
              border: i < filled
                  ? null
                  : Border.all(color: scheme.outline, width: 2),
              boxShadow: i < filled
                  ? [
                      BoxShadow(
                        color: (wrong ? scheme.error : scheme.primary)
                            .withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

/// Petite utilitaire de calcul de couleur (assombrit/éclaircit un hex).
class Lighten {
  static Color color(Color c) => Color.lerp(c, Colors.white, 0.18)!;
}
