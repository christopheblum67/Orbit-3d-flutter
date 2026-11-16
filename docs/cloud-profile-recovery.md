# Fiches de profils dans le cloud

Depuis **Compte cloud**, un compte non anonyme peut ouvrir « Configurer la
synchronisation chiffrée ». Le code cloud de 3 à 10 chiffres est indépendant du
compte de connexion : il doit être saisi sur chaque appareil et n'est pas
enregistré par cette fonction. Un code court est facile à deviner si les données
chiffrées sont copiées ; préférer un code long et unique. Sa perte rend le
catalogue chiffré irrécupérable. Confirmer le code avant la première sauvegarde.
Pour accéder aux données existantes protégées par une phrase, choisir « Utiliser
une ancienne phrase secrète » ; ce choix ne modifie pas le secret ni ne rechiffre
les données existantes.
La phrase peut être affichée temporairement à l'écran. Son affichage ne change
pas le chiffrement. Lors du chargement, elle est validée uniquement si un
catalogue chiffré existe ; sinon, aucune vérification n'est possible.

Le catalogue lui-même ne contient que les fiches de profils. Après chargement
du catalogue avec le secret, l'utilisateur peut cocher plusieurs profils locaux
ou tous les sélectionner, puis confirmer leur synchronisation en une fois. Les fiches absentes du catalogue
sont d'abord sauvegardées ; les profils homonymes restent distincts par leur
identifiant. Les fiches, favoris vidéo et radio, historiques récents, épisodes
vus et positions de lecture sont synchronisés pour chaque profil sélectionné.
Les préférences générales et les abonnements sont communs et synchronisés une
fois ; les URL et identifiants IPTV sont inclus dans le chiffrement. L'activation
du seul profil actif reste possible. La synchronisation reste active pendant la
session et vérifie le cloud périodiquement. Elle se verrouille au changement de
compte ou de secret et, en mode profil actif, au changement de profil. Le secret
doit être ressaisi après redémarrage. L'abonnement actif et les
résultats de test sont propres à chaque appareil ; un abonnement actif ne peut
pas être supprimé automatiquement par le cloud. L'ancienne synchronisation en
clair reste désactivée.

Après la sauvegarde d'une fiche, le catalogue est rechargé automatiquement.
Après récupération, sélectionnez le profil dans l'application, puis revenez
activer sa synchronisation avec la même phrase secrète.

L'historique général de la page Historique n'est pas synchronisé : il est
actuellement partagé entre les profils sur l'appareil.

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

## Essai du couplage TV par QR code

Le couplage est expérimental et masqué par défaut. Pour l'essayer après
configuration du backend, les deux appareils doivent utiliser une application
compilée avec `--dart-define=ORBIT_QR_PAIRING_ENABLED=true`. Sur le mobile,
connectez-vous, saisissez la phrase et chargez le catalogue, puis choisissez
« Associer une TV par QR code ». Sur la TV non connectée à un compte cloud,
choisissez « Associer cette TV par QR code ». Comparez les codes de
vérification, confirmez sur le mobile, puis vérifiez et confirmez le compte
affiché sur la TV. Ne partagez pas le QR code.

Pendant cet essai, les options de connexion Google sont masquées sur la TV
lorsque le couplage QR est activé. Elles restent disponibles sur le mobile,
qui doit être connecté à un compte non anonyme avant le couplage.

La TV utilise un compte anonyme temporaire isolé du compte principal. Le
mobile chiffre la phrase pour une clé éphémère détenue par la TV ; une fonction
de confiance émet un jeton Firebase personnalisé chiffré pour cette même clé.
Le serveur ne reçoit pas la phrase en clair et aucune donnée IPTV n'est
placée dans la session de couplage. L'identifiant de compte, l'adresse
affichée et les métadonnées de session restent visibles du serveur.
L'identifiant de session est aléatoire sur
256 bits et inutilisable après cinq minutes. Le document est supprimé
transactionnellement à la récupération ou à l'annulation ; si la réponse est
perdue, il faut recommencer. La TV tente aussi de supprimer son compte
anonyme temporaire.

Après le couplage QR, le catalogue est chargé automatiquement avec la phrase
transmise ; une erreur reste affichée et le chargement manuel reste possible.
Valider la saisie de la phrase lance également son chargement. Récupérez si
nécessaire les fiches, cochez les profils locaux souhaités et confirmez leur
synchronisation. Les contrôles de PIN de profil ne sont pas contournés.

Avant tout essai réel :

1. Activer Firebase Authentication anonyme et le fournisseur de connexion du
   mobile. Les deux appareils doivent appartenir au même projet Firebase.
2. Configurer Firebase App Check avec Play Integrity pour les applications et
   signatures utilisées. Les fonctions imposent App Check ; certains appareils
   TV peuvent ne pas être compatibles. Ne pas désactiver ce contrôle pour
   contourner une erreur.
3. Déployer séparément les fonctions de `functions` (Node.js 22, région
   `europe-west9`, Paris ; la base Firestore reste en `eur3`). Le choix de
   cette région ne garantit pas que tous les services ou toutes les données
   restent exclusivement en Europe. Le projet doit permettre Cloud Functions
   et le compte de
   service doit pouvoir signer les jetons personnalisés. Le déploiement peut
   entraîner des coûts. Après vérification du projet ciblé, la commande
   `firebase deploy --only functions --project ID_DU_PROJET` ne déploie pas
   les règles Firestore.
4. Comparer les règles Firestore réellement déployées avec `firestore.rules`
   avant toute modification. Les collections `pairing_sessions_v1` et
   `pairing_owners_v1` ne doivent être accessibles directement à aucun client :
   une règle permissive supplémentaire peut primer sur un refus explicite.
   Les fonctions serveur utilisent le SDK Admin.
5. Activer une politique Firestore TTL sur le champ `expiresAt` de ces deux
   collections pour nettoyer les sessions abandonnées. La suppression TTL est
   différée ; l'expiration est contrôlée par le serveur à chaque opération.
   Surveiller les quotas et les abus avant une ouverture générale.

Le code local et les tests simulés ne prouvent pas le déploiement des règles,
des fonctions ou d'App Check, ni le fonctionnement sur les appareils réels.
