import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Une étape du mini-tutoriel.
class TutorialStep {
  const TutorialStep(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
}

/// Renvoie le parcours de tutoriel **adapté au rôle** de l'utilisateur.
/// C'est ici que se reflète la logique métier : chaque rôle a un flux différent.
List<TutorialStep> tutorialStepsForRole(UserRole role) {
  switch (role) {
    case UserRole.producteur:
      return const [
        TutorialStep(Icons.agriculture_outlined, 'Crée ta boutique',
            'Présente ta production (ferme, vivriers…) en quelques infos.'),
        TutorialStep(Icons.inventory_2_outlined, 'Ajoute tes récoltes',
            'Mets tes produits en ligne avec prix, unité (kg, sac…) et stock.'),
        TutorialStep(Icons.bolt_outlined, 'Réponds aux demandes',
            'Les consommateurs publient leurs besoins en direct : propose ton offre.'),
        TutorialStep(Icons.event_available_outlined, 'Gère les réservations',
            'Accepte les réservations avec acompte et prépare les commandes.'),
      ];
    case UserRole.commercant:
      return const [
        TutorialStep(Icons.storefront_outlined, 'Crée ta boutique',
            'Configure ta boutique virtuelle en quelques secondes.'),
        TutorialStep(Icons.inventory_2_outlined, 'Gère ton stock',
            'Ajoute, modifie et suis le stock de tes produits.'),
        TutorialStep(Icons.bolt_outlined, 'Réponds aux demandes instantanées',
            'Vois les demandes proches et propose prix, quantité et délai.'),
        TutorialStep(Icons.bar_chart_outlined, 'Suis ton activité',
            'Dashboard : chiffre d\'affaires, commandes et top produits.'),
      ];
    case UserRole.consommateur:
      return const [
        TutorialStep(Icons.map_outlined, 'Découvre les commerçants proches',
            'Explore les boutiques autour de toi, triées par distance.'),
        TutorialStep(Icons.bolt_outlined, 'Publie une demande instantanée',
            'Décris ton besoin (ex: 20 kg d\'oignons) et reçois des offres.'),
        TutorialStep(Icons.event_available_outlined, 'Réserve avec acompte',
            'Bloque un produit en payant un petit acompte (simulé).'),
        TutorialStep(Icons.star_outline, 'Note tes achats',
            'Donne 5 étoiles et un avis après chaque échange.'),
      ];
    case UserRole.livreur:
      return const [
        TutorialStep(Icons.badge_outlined, 'Complète ton profil',
            'Indique ta zone et tes disponibilités de livraison.'),
        TutorialStep(Icons.local_shipping_outlined, 'Reçois des courses',
            'Accepte les livraisons proposées par les commerçants.'),
        TutorialStep(Icons.check_circle_outline, 'Livre & confirme',
            'Suis l\'itinéraire et confirme la livraison au client.'),
        TutorialStep(Icons.star_outline, 'Gagne en réputation',
            'De bonnes notes = plus de courses qui t\'arrivent.'),
      ];
    case UserRole.admin:
      return const [
        TutorialStep(Icons.admin_panel_settings_outlined, 'Espace admin',
            'Tu peux superviser les comptes, boutiques et contenus.'),
      ];
  }
}
