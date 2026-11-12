# Fiches de profils dans le cloud

Depuis **Compte cloud**, un compte non anonyme peut ouvrir « Sauvegarder ou
récupérer les fiches de profils ». La phrase secrète est indépendante du
compte de connexion : elle doit être saisie sur chaque appareil et n'est pas
enregistrée par cette fonction. Sa perte rend le catalogue chiffré
irrécupérable. Confirmer la phrase avant la première sauvegarde.

Le catalogue lui-même ne contient que les fiches de profils. Après chargement
du catalogue avec la phrase secrète, l'utilisateur peut activer séparément la
synchronisation chiffrée de la fiche du profil actif, de ses favoris,
historiques récents, épisodes vus et positions de lecture, s'il figure dans le
catalogue, ainsi que des préférences générales et des abonnements. Les URL et
identifiants IPTV sont inclus dans le chiffrement. Elle
reste active pendant la session, vérifie le cloud périodiquement et se
verrouille lors d'un changement de compte, de profil ou de phrase saisie. La phrase doit être
ressaisie après redémarrage. Les données d'un autre profil sont synchronisées
après sa sélection et un nouveau déverrouillage. L'abonnement actif et les
résultats de test sont propres à chaque appareil ; un abonnement actif ne peut
pas être supprimé automatiquement par le cloud. L'ancienne synchronisation en
clair reste désactivée.

L'historique général de la page Historique et les favoris radio ne font pas
partie de ces catégories synchronisées.

La fusion utilise un miroir local d'empreintes à clé stockée dans le coffre et
détecte les modifications
concurrentes. Un conflit interrompt la synchronisation sans arbitrage
automatique ; l'utilisateur peut choisir quelle version conserver pour les
éléments en conflit dans la catégorie concernée.

Le chargement est en lecture seule. La sauvegarde et la récupération exigent
un choix et une confirmation explicites. Une fiche portant le même identifiant
n'est jamais remplacée, côté cloud ou local ; des profils homonymes restent
distincts. Les sauvegardes sont chiffrées sur l'appareil avant leur envoi,
associées au compte et soumises à un contrôle de révision Firestore. Un conflit
nécessite de recharger ; aucune suppression cloud n'est effectuée. Les données
cloud éventuellement envoyées en clair par d'anciennes versions ne sont ni
migrées ni supprimées.

Les nouveaux codes PIN de profil sont enregistrés sous forme de dérivation
salée et accompagnent la fiche chiffrée. Les anciens codes restent compatibles
sans migration automatique ; pour remplacer un ancien code stocké en clair,
modifiez-le dans le profil. Un PIN à quatre chiffres reste une protection
limitée contre une recherche exhaustive.

Cette fonction requiert Firebase Auth et l'accès Firestore, ainsi que le
déploiement des règles `firestore.rules` correspondantes. Les règles présentes
dans le dépôt ne sont pas déployées automatiquement. La connexion, les règles
effectivement déployées et le parcours sur mobile et TV doivent être validés
sur le projet Firebase réel.
