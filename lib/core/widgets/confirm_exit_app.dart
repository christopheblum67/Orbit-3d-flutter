import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Demande de confirmation avant de fermer l'application.
///
/// Intercepte la touche retour / ESC (et toute tentative de sortie) afin
/// d'éviter une fermeture inopinée : affiche une boîte de dialogue avec les
/// choix « Oui » (fermer) ou « Non » (annuler).
class ConfirmExitApp extends StatefulWidget {
  final Widget child;

  const ConfirmExitApp({super.key, required this.child});

  @override
  State<ConfirmExitApp> createState() => _ConfirmExitAppState();
}

class _ConfirmExitAppState extends State<ConfirmExitApp> {
  bool _dialogOpen = false;

  Future<void> _confirmExit() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const _ExitConfirmDialog(),
    );
    _dialogOpen = false;
    if (shouldExit == true && context.mounted) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: widget.child,
    );
  }
}

class _ExitConfirmDialog extends StatelessWidget {
  const _ExitConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16181E),
      title: const Row(
        children: [
          Icon(Icons.power_settings_new_rounded,
              color: Color(0xFFFF6B6B), size: 26,),
          SizedBox(width: 10),
Text(
              'Quitter Orbit IPTV',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
        ],
      ),
      content: const Text(
        'Voulez-vous vraiment fermer l\'application ?',
        style: TextStyle(color: Colors.white70, fontSize: 15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Non',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold,),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Oui',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold,),
            ),
          ),
        ),
      ],
    );
  }
}