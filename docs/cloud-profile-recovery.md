# Fiches de profils dans le cloud

Depuis **Compte cloud**, un compte non anonyme peut ouvrir « Retrouver mes
profils sur mes appareils ». L'écran guide le choix des profils et présente les
options techniques dans des sections réservées aux adultes. Le code cloud de
3 à 10 chiffres est indépendant du compte de connexion : il doit être saisi sur
chaque appareil et n'est pas enregistré par cette fonction. Un adulte doit
choisir un code long et unique ; sa perte rend le catalogue chiffré
irrécupérable. Confirmer le code avant la première sauvegarde. Pour accéder aux
données existantes protégées par une phrase, ouvrir « Options pour un adulte »
et choisir « Utiliser un ancien code » ; ce choix ne modifie pas le secret ni
ne rechiffre les données existantes.
La phrase peut être affichée temporairement à l'écran. Son affichage ne change
pas le chiffrement. Lors du chargement, elle est validée uniquement si un
catalogue chiffré existe ; sinon, aucune vérification n'est possible.

Le catalogue lui-même ne contient que les fiches de profils. Le bouton « Voir
mes profils » charge le catalogue. L'utilisateur peut ensuite cocher les
profils voulus et choisir « Partager les profils cochés ».
Les profils sont présentés avec leur avatar et leur nom ; si plusieurs profils
portent le même nom, leur identifiant aide à les distinguer. Les actions
individuelles et les commandes de maintenance restent accessibles dans des
sections réservées aux adultes.
Les fiches sélectionnées absentes
localement sont récupérées, et celles absentes du catalogue sont sauvegardées ;
les profils homonymes restent distincts par leur
identifiant. Les fiches, favoris vidéo et radio, historiques récents, épisodes
vus et positions de lecture sont synchronisés pour chaque profil sélectionné.
Quand cet écran reste ouvert, le catalogue est également actualisé après une
synchronisation réussie afin de proposer les nouvelles fiches ; leur copie
reste soumise à confirmation.
Les préférences générales et les abonnements sont communs et synchronisés une
fois ; les URL et identifiants IPTV sont inclus dans le chiffrement. L'activation
du seul profil actif reste possible. La synchronisation reste active pendant la
session et écoute les modifications cloud des profils sélectionnés. Les
changements locaux ou distants sont mis en file rapidement, puis synchronisés
catégorie par catégorie ; le chiffrement et le réseau peuvent ajouter un délai.
La synchronisation peut dépasser 10 minutes selon l'appareil et le volume de
données. Une confirmation apparaît à la fin d'un partage complet lancé
manuellement ; les mises à jour automatiques ne génèrent pas de fenêtre.
Une vérification périodique toutes les cinq minutes reste active en secours.
Si l'écoute devient indisponible, un avertissement est affiché.
Le pourcentage indique la part des
catégories terminées parmi les étapes actuellement prévues, pas les octets
transférés ni le temps restant ; il peut évoluer si de nouvelles modifications
sont ajoutées pendant la synchronisation. Le chargement initial du catalogue
reste indéterminé lorsque sa durée n'est pas connue. Elle se verrouille au changement de
compte ou de secret et, en mode profil actif, au changement de profil. Le secret
doit être ressaisi après redémarrage. L'abonnement actif et les
résultats de test sont propres à chaque appareil ; un abonnement actif ne peut
pas être supprimé automatiquement par le cloud. L'ancienne synchronisation en
clair reste désactivée.

Dans Abonnements, une icône signale les configurations complètes identiques :
URL M3U identique ou même adresse Xtream et mêmes identifiants. Elle ne prouve
pas que le doublon vient du cloud. Aucun abonnement ni favori n'est supprimé.

Après la sauvegarde d'une fiche individuelle, le catalogue est rechargé
automatiquement. La sélection groupée récupère les fiches cloud manquantes et
active également leur synchronisation ; il faut ensuite sélectionner le profil
voulu dans l'application pour voir ses données. Une récupération individuelle
ne synchronise que la fiche : il faut ensuite activer sa synchronisation.
Si un profil n'apparaît pas dans le catalogue, sélectionnez-le sur son appareil
d'origine avec le même compte, puis rechargez le catalogue sur l'autre appareil.
Si une récupération groupée échoue après certaines copies, les fiches déjà
copiées restent présentes et la sélection peut être relancée.

L'historique général de la page Historique n'est pas synchronisé : il est
actuellement partagé entre les profils sur l'appareil.

La fusion utilise un miroir local d'empreintes à clé stockée dans le coffre et
détecte les modifications concurrentes. Au démarrage d'un partage, l'adulte
choisit une fois la source de référence : cet appareil ou le Cloud (l'autre
appareil). Les ajouts non conflictuels des deux côtés sont réunis ; ce choix
ne départage que les mêmes éléments modifiés des deux côtés et s'applique à
tous les profils et catégories de ce démarrage. Après cette convergence, les
changements continuent dans les deux sens. Les conflits ultérieurs demandent
toujours un choix explicite pour la catégorie concernée.

Le chargement est en lecture seule. La sauvegarde et la récupération exigent
un choix et une confirmation explicites. Une fiche portant le même identifiant
n'est jamais remplacée lors d'une sauvegarde, côté cloud ou local ; des profils
homonymes restent distincts. L'adulte peut supprimer une fiche et ses données
d'activité du Cloud sans effacer le profil local. La remise à zéro supprime les
données partagées, conserve les profils locaux et impose un nouveau code. Un
contrôle de génération chiffré verrouille les sessions actives et empêche les
anciennes versions du client ou un ancien code de republier après la remise à
zéro. Les sauvegardes sont chiffrées sur l'appareil avant leur envoi, associées
au compte et soumises à un contrôle de révision Firestore. Les données cloud
éventuellement envoyées en clair par d'anciennes versions ne sont ni migrées
ni supprimées.

Les règles Firestore correspondantes doivent être déployées avant la mise à
jour du client : elles valident le contrôle de génération, autorisent la
suppression des documents de synchronisation et rejettent les écritures des
anciennes versions.

Les nouveaux codes PIN de profil nécessitent deux saisies identiques puis
l'enregistrement du profil. Ils sont stockés sous forme de dérivation salée
et accompagnent la fiche chiffrée. Les
réglages avancés permettent de supprimer les PIN de tous les profils locaux ;
pour les profils sélectionnés dans un partage Cloud actif, cette modification
se synchronise également. Les anciens codes restent compatibles sans migration
automatique ; pour remplacer un ancien code stocké en clair, modifiez-le dans
le profil. Un PIN à quatre chiffres reste une protection limitée contre une
recherche exhaustive.

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
mobile chiffre la phrase et les identifiants des profils choisis pour une clé
éphémère détenue par la TV ; une fonction
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
transmise. Si la sélection était publiée sur le téléphone, la TV récupère les
mêmes identifiants et démarre leur synchronisation après le choix de la source
des conflits. Une erreur reste affichée et le chargement manuel reste
possible. Valider la saisie de la phrase lance également son chargement. Les
contrôles de PIN de profil ne sont pas contournés.

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
