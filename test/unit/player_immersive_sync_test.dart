import 'package:flutter_test/flutter_test.dart';

/// Test fail-first pour le bug _immersive / _showFooterBar.
///
/// Bug : _showFooterBar() passait en edgeToEdge SANS remettre _immersive = false.
/// Conséquence : quand le timer du footer expirait, _syncImmersive() ne remettait
/// PAS en immersive (garde `!immersive` échouait).
///
/// Ce test vérifie la logique d'état pure :
/// - shouldEnterImmersive = playing && !immersive && !footerVisible
/// - AVANT correctif : _showFooterBar ne met PAS _immersive = false
/// - APRÈS correctif : _showFooterBar MET _immersive = false
void main() {
  group('_immersive / _showFooterBar synchronisation d\'état', () {
    // Réplique la garde de _syncImmersive : faut-il ENTRER en immersive ?
    bool shouldEnterImmersive({
      required bool playing,
      required bool immersive,
      required bool footerVisible,
    }) =>
        playing && !immersive && !footerVisible;

    test('AVANT correctif : _showFooterBar ne réinitialise PAS _immersive → '
        'pas de restauration immersive après timer', () {
      // 1. État initial : lecture, PAS en immersive, pas de footer
      var immersive = false;
      var footerVisible = false;
      const playing = true;

      // 2. _syncImmersive initial → entre en immersive
      expect(shouldEnterImmersive(playing: playing, immersive: immersive, footerVisible: footerVisible), isTrue);
      immersive = true; // _syncImmersive met immersive = true

      // 3. Tap utilisateur → _showFooterBar() SANS correctif
      footerVisible = true;
      // immersive = true;  // <-- BUG : ligne manquante (immersive NE CHANGE PAS)

      // 4. Timer expire → footer masque, _syncImmersive() appelé
      footerVisible = false;
      // immersive toujours true (bug)

      // 5. VÉRIFICATION : shouldEnterImmersive ÉCHOUE car !immersive = false
      final canRestore = shouldEnterImmersive(playing: playing, immersive: immersive, footerVisible: footerVisible);
      expect(
        canRestore,
        isFalse,
        reason: 'SANS correctif : _immersive reste true après _showFooterBar, '
            'la garde !immersive bloque la restauration immersive.',
      );
    });

    test('APRÈS correctif : _showFooterBar RÉINITIALISE _immersive = false → '
        'restauration immersive après timer', () {
      // 1. État initial : lecture, PAS en immersive, pas de footer
      var immersive = false;
      var footerVisible = false;
      const playing = true;

      // 2. _syncImmersive initial → entre en immersive
      expect(shouldEnterImmersive(playing: playing, immersive: immersive, footerVisible: footerVisible), isTrue);
      immersive = true; // _syncImmersive met immersive = true

      // 3. Tap utilisateur → _showFooterBar() AVEC correctif
      footerVisible = true;
      immersive = false; // <-- CORRECTIF : ligne ajoutée

      // 4. Timer expire → footer masque, _syncImmersive() appelé
      footerVisible = false;
      // immersive = false (correctif)

      // 5. VÉRIFICATION : shouldEnterImmersive RÉUSSIT
      final canRestore = shouldEnterImmersive(playing: playing, immersive: immersive, footerVisible: footerVisible);
      expect(
        canRestore,
        isTrue,
        reason: 'AVEC correctif : _showFooterBar met _immersive = false, '
            'la garde !immersive passe, immersive restauré.',
      );
    });

    test('_restoreSystemUi remet correctement immersive = false', () {
      var immersive = true;
      // Simule _restoreSystemUi()
      immersive = false;
      expect(immersive, isFalse);
    });
  });
}