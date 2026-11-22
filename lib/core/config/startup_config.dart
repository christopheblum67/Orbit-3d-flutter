/// Configuration du démarrage — cache-first.
///
/// Basculer [kCacheFirstStartup] à `false` pour revenir au comportement
/// précédent (écran de démarrage bloquant `/startup` avec refresh complet).
///
/// Cache-first : l'accueil s'affiche immédiatement avec les données du cache
/// Hive, et le refresh s'exécute en arrière-plan via `_autoRefreshIfStale()`.
/// L'écran `/startup` reste disponible pour le rollback (premier lancement,
/// ajout d'abonnement) en mettant le flag à `false`.
const bool kCacheFirstStartup = true;
