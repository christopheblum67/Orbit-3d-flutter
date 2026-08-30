#!/usr/bin/env bash
# Script de création des labels de triage pour le dépôt Orbit-3d-flutter.
# Prérequis : gh CLI installé et authentifié.
set -euo pipefail
cd "$(dirname "$0")/.."

REPO="${1:-christopheblum67/Orbit-3d-flutter}"

echo "Création/validation des labels sur $REPO ..."

# Approche simple avec gh : définir les labels manuellement
declare -a LABELS=(
  "criticality:critique|🔴 Critique - bloquant|b60205"
  "criticality:eleve|🟠 Élevé - fn majeure en panne|d93f0b"
  "criticality:moyen|🟡 Moyen|fbca04"
  "criticality:faible|🟢 Faible - mineur|0e8a16"
  "triage-required|En attente de triage|e4e669"
  "en-cours|En cours de correction|0052cc"
  "correctif-prepare|Correctif développé, en attente build/test|1d76db"
  "en-test-boucle|Correctif déployé bêta, en attente validation|dedede"
  "corrige|Bug corrigé et validé|7057ff"
  "duplique|Bug déjà signalé|d4c5f9"
  "non-reproductible|Impossible de reproduire|ffffff"
  "phase-corrective|Rattaché à une phase de correction|f9d0c4"
  "phase-1|Correctif phase 1 (critiques/élevés)|f9d0c4"
  "phase-2|Correctif phase 2 (moyens)|f9d0c4"
  "phase-3|Correctif phase 3 (faibles)|f9d0c4"
)

for entry in "${LABELS[@]}"; do
  IFS='|' read -r name desc color <<< "$entry"
  echo "  -> $name"
  gh label create "$name" --description "$desc" --color "$color" --repo "$REPO" 2>/dev/null || \
    gh label edit "$name" --description "$desc" --color "$color" --repo "$REPO" 2>/dev/null || \
    echo "     (warning: impossible de créer/mettre à jour $name)"
done

echo "Terminé. Labels prêts."
