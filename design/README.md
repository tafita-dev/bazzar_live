# Bazzar — Refonte de présentation

Ouvrir `maquette-complete.html` dans un navigateur pour parcourir 16 exemples répartis entre client, vendeur, livreur et compte. `maquette-bazzar.html` conserve les vues détaillées de connexion et d’accueil. Les données sont fictives ; les éléments sont des exemples visuels. L’interface de production est développée dans `lib/` en Flutter.

## Direction graphique

- Violet principal `#7C3AED`, violet profond `#30205C`, fond lavande `#F8F7FC`.
- Thème clair uniforme, y compris lorsque le téléphone utilise le mode sombre. Les surfaces vidéo et caméra restent sombres. Ce choix évite de mélanger les cartes claires personnalisées avec les couleurs de texte d’un thème système sombre.
- Cartes blanches avec bordures discrètes, angles de 20 à 28 px.
- Hiérarchie claire : titre, explication courte, action principale.
- Libellés persistants sur les champs de connexion, remplissage automatique, contraste renforcé.
- Filtres natifs sélectionnables et défilables horizontalement sur les petits écrans.
- Bouton explicite pour regarder un live ou revoir un replay, utilisant la navigation existante.
- Barres de navigation tenant compte de la marge système Android et du grossissement du texte.

## Périmètre développé

La refonte couvre les pages et composants de présentation de toute l’application :

- Connexion, inscription, chargement du compte, erreurs de profil et splash.
- Accueil client, listes et détails des commandes, recherche de réservation.
- Catalogue vendeur, catégories, produits par catégorie, création de produit et catégorie.
- Tableau de bord vendeur, indicateurs, graphique, commandes et menu latéral.
- Profils client/vendeur et livreur, formulaires de modification.
- Liste des livreurs, création de livreur, historique, scanner et détails de livraison.
- Préparation d’un live, lecteur live, fiches produits, panier, confirmation et QR code.
- Navigation des trois rôles, dialogues, notifications et prise de photo.

Les couleurs sont centralisées dans `lib/core/theme/bazzar_colors.dart`. Les introductions, états vides, titres et mises en page de collections sont dans `lib/core/widgets/bazzar_ui.dart`. Les listes principales de produits et commandes utilisent un en-tête défilant afin de rester accessibles sur écran compact. Les formulaires de catégorie et de recherche peuvent défiler lorsque le clavier est ouvert. Les boutons de connexion et d’inscription peuvent grandir avec leur texte.

Aucun changement des repositories, providers, modèles, routes, requêtes Supabase, règles de commande ou calculs. Les boutons sans action du fil (recherche, notifications, menu, réactions) ont été retirés de la présentation. Le rafraîchissement, les filtres existants et l’ouverture des lives sont conservés.

## Contrôle visuel à effectuer sur Android

Vérifier la connexion avec clavier ouvert, les textes agrandis, les navigations avec gestes et boutons système, ainsi que les états chargement/vide/erreur du fil. La maquette est une référence de design, pas une capture du rendu Flutter.

Les tests ciblés de `test/bazzar_ui_test.dart` couvrent la mise en page en 320 × 568 avec un texte agrandi à 160 %, le clavier sur la connexion, l’inscription et le défilement d’une collection. Ils isolent la présentation sans exécuter de connexion ou de commande réelle. La navigation et les parcours complets avec données doivent être contrôlés sur appareil. Le SDK Flutter local contient une assertion incohérente dans `NavigatorState.dispose` ; il n’a pas été modifié par cette refonte.
