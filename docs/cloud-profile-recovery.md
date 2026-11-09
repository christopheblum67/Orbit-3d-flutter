# Fiches de profils dans le cloud

Depuis **Compte cloud**, un compte non anonyme peut ouvrir « Sauvegarder ou
récupérer les fiches de profils ». La phrase secrète est indépendante du
compte de connexion : elle doit être saisie sur chaque appareil et n'est pas
enregistrée par cette fonction. Sa perte rend le catalogue chiffré
irrécupérable. Confirmer la phrase avant la première sauvegarde.

Le catalogue ne contient que les fiches de profils. Il ne sauvegarde ni
favoris, historiques, positions de lecture, abonnements, sources IPTV ou
préférences globales. La synchronisation complète et automatique n'est pas
disponible. L'ancienne synchronisation en clair reste désactivée.

Le chargement est en lecture seule. La sauvegarde et la récupération exigent
un choix et une confirmation explicites. Une fiche portant le même identifiant
n'est jamais remplacée, côté cloud ou local ; des profils homonymes restent
distincts. Les sauvegardes sont chiffrées sur l'appareil avant leur envoi,
associées au compte et soumises à un contrôle de révision Firestore. Un conflit
nécessite de recharger ; aucune suppression cloud n'est effectuée. Les données
cloud éventuellement envoyées en clair par d'anciennes versions ne sont ni
migrées ni supprimées.

Cette fonction requiert Firebase Auth et l'accès Firestore, ainsi que le
déploiement des règles `firestore.rules` correspondantes. Les règles présentes
dans le dépôt ne sont pas déployées automatiquement. La connexion, les règles
effectivement déployées et le parcours sur mobile et TV doivent être validés
sur le projet Firebase réel.
