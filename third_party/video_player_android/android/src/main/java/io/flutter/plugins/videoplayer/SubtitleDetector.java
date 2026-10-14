// Copyright 2026 The Orbit Project Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.media3.common.C;
import androidx.media3.common.Format;
import androidx.media3.common.Player;
import androidx.media3.common.Tracks;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Détecteur de sous-titres embarqués exposés par Media3.
 *
 * <p>Composant PURE, dédié et autonome : il n'accède pas à Internet, ne modifie pas les paramètres
 * de sélection et ne parle pas à l'UI Flutter. Son seul rôle est de produire un résultat structuré
 * ({@link DetectionResult}) que le gestionnaire de sous-titres interprétera.
 *
 * <p>Trois règles gouvernent ce composant :
 *
 * <ul>
 *   <li>détecter une piste ne signifie pas qu'elle est sélectionnée ni que son texte est affiché ;
 *   <li>une piste déclarée « française » n'est pas nécessairement exploitable ({@code supported}),
 *       ni un vrai doublage (les pistes de commentaire ne doivent pas compter comme du français) ;
 *   <li>l'absence de piste au tout début de la lecture ne prouve pas que la vidéo n'en contient
 *       aucune — le gestionnaire doit combiner le résultat avec l'état du lecteur.
 * </ul>
 *
 * <p>Aucune dépendance à {@code media3-ui} : uniquement {@code media3-common} ({@code Tracks}).
 */
final class SubtitleDetector {

  /** États de la détection, tels que définis par le cahier des charges. */
  enum Status {
    /** Une piste française adaptée est disponible et prise en charge. */
    FRENCH_AVAILABLE,
    /** Une piste française est déjà sélectionnée. */
    FRENCH_SELECTED,
    /** Aucune piste française exploitable n'a été détectée. */
    FRENCH_UNAVAILABLE,
    /** Les pistes ne sont pas encore suffisamment connues (préparation en cours). */
    DETECTION_PENDING
  }

  /** Métadonnées utiles d'une piste de sous-titres, sans lien avec la sélection elle-même. */
  static final class SubtitleTrackInfo {
    /** Identifiant {@code "<groupIndex>_<trackIndex>"}, au format du canal « tracks » existant. */
    final String id;
    /** Langue normalisée ({@code "fr"}, {@code "en"}, {@code "und"}…). */
    final String language;
    final String label;
    final String mimeType;
    final boolean supported;
    final boolean selected;
    final boolean forced;
    final boolean defaultTrack;
    /** Piste destinée aux personnes sourdes / malentendantes (déduit du libellé). */
    final boolean sdh;

    SubtitleTrackInfo(
        String id,
        String language,
        @Nullable String label,
        @Nullable String mimeType,
        boolean supported,
        boolean selected,
        boolean forced,
        boolean defaultTrack,
        boolean sdh) {
      this.id = id;
      this.language = language;
      this.label = label;
      this.mimeType = mimeType;
      this.supported = supported;
      this.selected = selected;
      this.forced = forced;
      this.defaultTrack = defaultTrack;
      this.sdh = sdh;
    }

    @Override
    public String toString() {
      return "{id="
          + id
          + " lang="
          + language
          + (label == null ? "" : " label=\"" + label + "\"")
          + (mimeType == null ? "" : " mime=" + mimeType)
          + " supported="
          + supported
          + " selected="
          + selected
          + " forced="
          + forced
          + " sdh="
          + sdh
          + "}";
    }
  }

  /** Sortie structurée de {@link #detect(Player)}. */
  static final class DetectionResult {
    final Status status;
    final List<SubtitleTrackInfo> tracks;

    DetectionResult(Status status, List<SubtitleTrackInfo> tracks) {
      this.status = status;
      this.tracks = tracks;
    }

    @Override
    public String toString() {
      return "status=" + status + " tracks=" + tracks;
    }
  }

  /**
   * Inspecte les pistes texte exposées par le lecteur et classe le français disponible.
   *
   * <p>Ne se fie jamais à la seule présence d'une piste : seules les pistes {@code supported}
   * comptent pour « français disponible ». Une piste française non prise en charge reste listée,
   * mais ne déclenche pas {@code FRENCH_AVAILABLE}.
   */
  DetectionResult detect(Player player) {
    Tracks currentTracks = player.getCurrentTracks();
    if (currentTracks == null) {
      // Lecteur pas encore prêt (mock de test, préparation en cours) : on
      // traite comme « pistes inconnues » plutôt que de crasher.
      return new DetectionResult(Status.DETECTION_PENDING, new ArrayList<>());
    }
    List<SubtitleTrackInfo> foundTracks = new ArrayList<>();

    boolean frenchAvailable = false;
    boolean frenchSelected = false;

    int groupIndex = 0;
    for (Tracks.Group group : currentTracks.getGroups()) {
      if (group.getType() != C.TRACK_TYPE_TEXT) {
        groupIndex++;
        continue;
      }
      for (int trackIndex = 0; trackIndex < group.length; trackIndex++) {
        Format format = group.getTrackFormat(trackIndex);
        String normalizedLanguage = normalizeLanguage(format.language, format.label);

        SubtitleTrackInfo info =
            new SubtitleTrackInfo(
                groupIndex + "_" + trackIndex,
                normalizedLanguage,
                format.label,
                format.sampleMimeType,
                group.isTrackSupported(trackIndex),
                group.isTrackSelected(trackIndex),
                (format.selectionFlags & C.SELECTION_FLAG_FORCED) != 0,
                (format.selectionFlags & C.SELECTION_FLAG_DEFAULT) != 0,
                isSdh(format.label));
        foundTracks.add(info);

        if (isFrench(info.language) && info.supported) {
          frenchAvailable = true;
          if (info.selected) {
            frenchSelected = true;
          }
        }
      }
      groupIndex++;
    }

    Status status;
    if (frenchSelected) {
      status = Status.FRENCH_SELECTED;
    } else if (frenchAvailable) {
      status = Status.FRENCH_AVAILABLE;
    } else if (currentTracks.getGroups().isEmpty()) {
      // Media3 ne signale encore rien : préparation en cours. Ne PAS conclure
      // « aucune piste » — un sous-titre peut apparaître après coup (flux
      // IPTV, variante adaptative tardive).
      status = Status.DETECTION_PENDING;
    } else {
      status = Status.FRENCH_UNAVAILABLE;
    }

    return new DetectionResult(status, foundTracks);
  }

  /**
   * Normalise la langue d'une piste, avec repli raisonné sur le libellé.
   *
   * <p>Le libellé n'est pas une preuve : {@code "French Commentary"} ou {@code "French (AD)"}
   * (audio-description) sont des pistes de commentaire, pas des sous-titres français complets. On
   * ne retient le libellé que s'il nomme clairement le français, en excluant ces cas.
   */
  private static String normalizeLanguage(@Nullable String language, @Nullable String label) {
    if (language != null && !language.trim().isEmpty()) {
      return language.trim().replace('_', '-').toLowerCase(Locale.ROOT);
    }
    if (isFrenchLabel(label)) {
      return "fr";
    }
    return "und";
  }

  /** La langue normalisée désigne-t-elle le français ? */
  private static boolean isFrench(@Nullable String language) {
    if (language == null) {
      return false;
    }
    String value = language.replace('_', '-').toLowerCase(Locale.ROOT);
    return value.equals("fr") || value.equals("fra") || value.equals("fre") || value.startsWith("fr-");
  }

  /** Le libellé nomme-t-il clairement des sous-titres français (hors commentaire/AD) ? */
  private static boolean isFrenchLabel(@Nullable String label) {
    if (label == null) {
      return false;
    }
    String value = label.trim().toLowerCase(Locale.ROOT);
    if (!value.contains("français")
        && !value.contains("francais")
        && !value.contains("french")) {
      return false;
    }
    // « French Commentary », « French (AD) », « French Descriptive »… ne sont pas
    // des pistes de sous-titres français complets.
    return !value.contains("commentary")
        && !value.contains("audio description")
        && !value.contains("descriptive")
        && !value.contains(" ad");
  }

  /** Une piste destinée aux sourds / malentendants, déduite du libellé. */
  private static boolean isSdh(@Nullable String label) {
    if (label == null) {
      return false;
    }
    String value = label.toLowerCase(Locale.ROOT);
    return value.contains("sdh")
        || value.contains("hearing impaired")
        || value.contains("malentendant");
  }
}