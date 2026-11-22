import 'package:flutter/material.dart';

/// Helpers d'accessibilité pour Android TV + TalkBack (Android Phone).
///
/// Objectif : rendre les éléments focusables D-pad explicites pour les
/// lecteurs d'écran, tout en préservant l'UX TV (pas d'intrusion sur D-pad).
class Accessibility {
  /// Enveloppe un élément interactif avec des labels/traits TalkBack.
  ///
  /// Sur Android TV, TalkBack est rarement actif (navigation D-pad). Sur mobile,
  /// cela améliore fortement la découvrabilité.
  static Widget labeled({
    required Widget child,
    String? label,
    String? hint,
    bool isButton = false,
    bool isSelected = false,
    bool isFocusable = true,
    bool isHeader = false,
    bool isLiveRegion = false,
    String? onTapHint,
  }) {
    if (label == null && hint == null && !isButton && !isSelected && !isHeader && !isLiveRegion && onTapHint == null) {
      return child;
    }
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      selected: isSelected,
      focusable: isFocusable,
      header: isHeader,
      liveRegion: isLiveRegion,
      onTapHint: onTapHint,
      child: child,
    );
  }

  /// Ajoute un live region (annonces vocales TalkBack) pour états transitoires
  /// (buffering, erreur, chargement...).
  static Widget live({
    required Widget child,
    String? label,
    bool assertive = false,
  }) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: child,
    );
  }

  /// Marque un groupe logique pour la navigation TalkBack (landmarks).
  static Widget group({
    required Widget child,
    String? label,
    bool isHeader = false,
  }) {
    return Semantics(
      container: true,
      explicitChildNodes: false,
      label: label,
      header: isHeader,
      child: child,
    );
  }
}

/// Extension pratique pour appliquer rapidement Semantics TV/TalkBack.
extension AccessibilityExtension on Widget {
  Widget a11yLabel(String label, {bool button = false, bool selected = false}) =>
      Semantics(label: label, button: button, selected: selected, child: this);

  Widget a11yButton(String label, {String? hint}) =>
      Semantics(label: label, hint: hint, button: true, child: this);

  Widget a11yHeader(String label) => Semantics(label: label, header: true, child: this);

  Widget a11yLive(String? label, {bool assertive = false}) =>
      Semantics(liveRegion: true, label: label, child: this);
}
