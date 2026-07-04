import 'package:flutter/material.dart';

/// Palette de **Dioula Market** — refonte « marché ivoirien » :
/// tons terre chauds (terracotta / ocre / beige profond), surfaces crème,
/// cartes blanches à ombres douces, et couleurs sémantiques complètes.
///
/// On garde l'inspiration des templates (Foodly + Rive) mais en **plus riche
/// et plus coloré**, façon vraie app de production.
///
/// ⚠️ Compatibilité : les anciens noms (`green`, `orange`, `title`…) sont
/// conservés en **alias** pour que les écrans existants compilent et adoptent
/// automatiquement la nouvelle palette. Les nouveaux écrans utilisent les noms
/// sémantiques (`clay`, `ocre`, `beige`, `cream`, `ink`, `info`…).
class AppColors {
  AppColors._();

  // ---------------- MARQUE (tons terre) ----------------
  /// Terracotta — couleur d'action principale (boutons / CTA).
  static const clay = Color(0xFFE0703A);
  static const clayDark = Color(0xFFC85A28);

  /// Ocre / ambre — accents, badges, mises en avant secondaires.
  static const ocre = Color(0xFFF2A03D);

  /// Beige profond — couleur de marque (en-têtes, logo, aplats doux).
  static const beige = Color(0xFFC9A06B);
  static const beigeDeep = Color(0xFFB07A46);

  // ---------------- SURFACES CLAIRES ----------------
  /// Fond crème (scaffold en thème clair) — blanc cassé chaud.
  static const cream = Color(0xFFFBF4EA);
  static const surfaceLight = Colors.white; // cartes
  static const inputLight = Color(0xFFF6EEE1); // fond des champs
  static const borderLight = Color(0xFFEFE5D6);
  static const bgLight = cream; // alias rétro

  // ---------------- TEXTE ----------------
  static const ink = Color(0xFF2A2018); // titres (warm near-black)
  static const title = ink; // alias rétro
  static const body = Color(0xFF867B6C); // texte secondaire (warm gray)

  // ---------------- SURFACES SOMBRES (warm dark) ----------------
  static const bgDark = Color(0xFF1C1712); // scaffold sombre
  static const cardDark = Color(0xFF27201A); // cartes
  static const surfaceDark = Color(0xFF221C16);
  static const inputDark = Color(0xFF2E251D);
  static const borderDark = Color(0xFF3A2F25);
  static const bodyDark = Color(0xFFB9AC9B);

  // ---------------- SÉMANTIQUE ----------------
  static const success = Color(0xFF3FA86A); // vert (validé / en stock)
  static const warning = Color(0xFFE8A93C); // ambre (alerte stock bas)
  static const info = Color(0xFF3E84C9); // bleu (information / frais)
  static const danger = Color(0xFFE1493B); // rouge (erreur / suppression)

  // Badges spécifiques (lisibilité produits).
  static const halal = success; // pastille « Halal »
  static const promo = clay; // pastille « Promo »
  static const fresh = info; // pastille « Frais »

  // ---------------- OMBRES ----------------
  static const shadowLight = Color(0xFF6B5B45);
  static const shadowDark = Colors.black;

  // ---------------- ALIAS RÉTRO-COMPATIBLES ----------------
  /// Ancien « vert » primaire → désormais la terracotta (CTA).
  static const green = clay;

  /// Ancien « orange » accent → désormais l'ocre/ambre.
  static const orange = ocre;

  // ---------------- DÉGRADÉS ----------------
  /// Dégradé CTA (boutons premium / accents).
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEE8A4E), clay],
  );

  /// Dégradé de marque (beige) — aplats doux d'en-tête.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [beige, beigeDeep],
  );

  /// Dégradé chaud des bannières promo (en-têtes colorés).
  static const headerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFEE8A4E), clay],
  );

  /// Dégradé d'arrière-plan de l'onboarding / auth — **brun chaud profond**
  /// (façon Rive, re-teinté terre).
  static const authGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A2A1E), bgDark],
  );
}
