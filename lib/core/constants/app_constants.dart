// Constantes et énumérations partagées de Dioula Market.
//
// Les valeurs `value` correspondent EXACTEMENT aux chaînes stockées en base
// (colonnes `text` avec CHECK). Garder ces deux côtés synchronisés.

class AppInfo {
  AppInfo._();
  static const appName = 'Dioula Market';
  static const tagline = 'Le marché local, en temps réel.';
}

/// Comptes de démonstration créés par `supabase/seed.sql` (+ `step22.sql`
/// pour l'admin). Ils partagent le mot de passe [password]. La **2FA simulée**
/// s'applique à toutes les connexions, comptes démo compris (code affiché).
class DemoAccounts {
  DemoAccounts._();

  static const password = 'demo1234';

  static const emails = <String>{
    'samira@demo.ci', // Consommatrice — Cocody
    'raoul@demo.ci', // Commerçant — « Chez Brou », Adjamé
    'jacob@demo.ci', // Producteur — « Ferme Kouamé », Agboville
    'kader@demo.ci', // Livreur — Yopougon
    'anais@demo.ci', // Commerçante — « Maquis Fatim », Treichville
    'admin@demo.ci', // Admin plateforme — supervision & modération
  };

  static bool isDemo(String? email) =>
      email != null && emails.contains(email.trim().toLowerCase());
}

/// Rôles utilisateur (stockés sur la table `profiles`).
enum UserRole {
  producteur('producteur', 'Producteur'),
  commercant('commercant', 'Commerçant'),
  consommateur('consommateur', 'Consommateur'),
  livreur('livreur', 'Livreur'),
  admin('admin', 'Admin');

  const UserRole(this.value, this.label);
  final String value;
  final String label;

  static UserRole fromValue(String? v) =>
      UserRole.values.firstWhere((r) => r.value == v,
          orElse: () => UserRole.consommateur);
}

/// Raccourcis de rôle pour piloter la logique métier (navigation, services…).
extension UserRoleX on UserRole {
  /// Vend des produits (a une boutique) : commerçant ou producteur.
  bool get isSeller =>
      this == UserRole.commercant || this == UserRole.producteur;

  bool get isConsumer => this == UserRole.consommateur;
  bool get isCourier => this == UserRole.livreur;
  bool get isAdmin => this == UserRole.admin;
}

/// Statut d'une demande instantanée (`requests`).
enum RequestStatus {
  ouverte('ouverte', 'Ouverte'),
  pourvue('pourvue', 'Pourvue'),
  expiree('expiree', 'Expirée'),
  annulee('annulee', 'Annulée');

  const RequestStatus(this.value, this.label);
  final String value;
  final String label;
}

/// Statut d'une offre faite par un commerçant (`offers`).
enum OfferStatus {
  proposee('proposee', 'Proposée'),
  acceptee('acceptee', 'Acceptée'),
  refusee('refusee', 'Refusée');

  const OfferStatus(this.value, this.label);
  final String value;
  final String label;
}

/// Statut d'une réservation avec acompte (`reservations`).
enum ReservationStatus {
  enAttente('en_attente', 'En attente'),
  payee('payee', 'Acompte payé'),
  confirmee('confirmee', 'Confirmée'),
  terminee('terminee', 'Terminée'),
  annulee('annulee', 'Annulée'),
  expiree('expiree', 'Expirée');

  const ReservationStatus(this.value, this.label);
  final String value;
  final String label;
}

/// Statut d'une commande (`orders`).
enum OrderStatus {
  enCours('en_cours', 'En cours'),
  preparee('preparee', 'Préparée'),
  enLivraison('en_livraison', 'En livraison'),
  livree('livree', 'Livrée'),
  annulee('annulee', 'Annulée');

  const OrderStatus(this.value, this.label);
  final String value;
  final String label;
}

/// Unités de vente proposées (formulaires produit / demande).
const List<String> kUnits = [
  'kg',
  'sac',
  'litre',
  'régime',
  'tas',
  'carton',
  'sachet',
  'portion',
  'unité',
];

/// Pourcentage d'acompte payé à la réservation (simulé).
const double kDepositRate = 0.30;

/// Répartition de l'acompte si la réservation **expire** sans retrait :
/// 40 % remboursés à l'acheteur, 40 % au vendeur, 20 % à la plateforme.
const double kExpiryRefundBuyerRate = 0.40;
const double kExpirySellerRate = 0.40;

/// On peut annuler une réservation jusqu'à 12 h avant l'échéance (retrait).
const int kReservationCancelCutoffHours = 12;

/// Seuil d'alerte de stock bas (notification au vendeur).
const int kLowStockThreshold = 5;

/// Montant (FCFA) au-delà duquel un consommateur doit avoir renseigné sa CNI
/// (vérification d'identité) avant de valider une réservation/commande.
const double kLargeOrderThreshold = 250000;
