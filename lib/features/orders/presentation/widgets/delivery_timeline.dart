import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Étapes vues par le **client** (6).
const clientSteps = <(IconData, String)>[
  (Icons.inventory_2_outlined,
      'Le livreur n\'a pas encore réceptionné votre colis'),
  (Icons.two_wheeler, 'Le livreur a récupéré votre colis'),
  (Icons.local_shipping, 'La livraison est en cours'),
  (Icons.near_me, 'Le livreur est presque là, gardez votre téléphone en main !'),
  (Icons.pin_drop, 'Le livreur est là'),
  (Icons.check_circle, 'Votre colis a été réceptionné avec succès !'),
];

/// Étapes vues par le **vendeur** (3).
const vendorSteps = <(IconData, String)>[
  (Icons.two_wheeler, 'Le livreur se dirige vers vous'),
  (Icons.local_shipping, 'Le livreur a réceptionné le colis, livraison en cours'),
  (Icons.check_circle, 'Le client a reçu le colis !'),
];

/// Ce que le **livreur** confirme à chaque appui (index = delivery_step actuel).
const _courierActions = <String>[
  'J\'ai récupéré le colis', // 0 → 1
  'Je suis en route', // 1 → 2
  'Je suis presque là', // 2 → 3
  'Je suis arrivé', // 3 → 4
  'Confirmer la livraison', // 4 → 5 (livré)
];

String courierNextActionLabel(int step) =>
    (step >= 0 && step < _courierActions.length)
        ? _courierActions[step]
        : 'Confirmer la livraison';

/// Roadmap de suivi d'un colis, pilotée par `deliveryStep` (0→5) et `status`.
/// Vue **client** (6 étapes) ou **vendeur** (3 étapes).
class DeliveryTimeline extends StatelessWidget {
  const DeliveryTimeline({
    super.key,
    required this.status,
    required this.deliveryStep,
    this.sellerView = false,
  });

  final String status;
  final int deliveryStep;
  final bool sellerView;

  @override
  Widget build(BuildContext context) {
    if (status == 'annulee') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.danger),
            SizedBox(width: 10),
            Expanded(child: Text('Commande annulée.')),
          ],
        ),
      );
    }

    final steps = sellerView ? vendorSteps : clientSteps;
    final completed = sellerView
        ? _vendorCompleted(status, deliveryStep)
        : _clientCompleted(status, deliveryStep);
    final waiting = status == 'en_cours' || status == 'preparee';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (waiting)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.hourglass_top, size: 18, color: AppColors.warning),
                SizedBox(width: 8),
                Expanded(child: Text('En attente d\'un livreur…')),
              ],
            ),
          ),
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            icon: steps[i].$1,
            title: steps[i].$2,
            done: i < completed,
            current: i == completed && completed < steps.length && !waiting,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }

  int _clientCompleted(String status, int step) =>
      status == 'livree' ? 6 : (status == 'en_livraison' ? step : 0);

  int _vendorCompleted(String status, int step) => status == 'livree'
      ? 3
      : (status == 'en_livraison' ? (step >= 1 ? 1 : 0) : 0);
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.icon,
    required this.title,
    required this.done,
    required this.current,
    required this.isLast,
  });

  final IconData icon;
  final String title;
  final bool done;
  final bool current;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final active = done || current;
    final nodeColor = done
        ? AppColors.success
        : (current ? AppColors.clay : AppColors.body.withValues(alpha: 0.3));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: active ? nodeColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeColor, width: 2),
                ),
                child: Icon(
                  done ? Icons.check : icon,
                  size: 18,
                  color: active ? Colors.white : nodeColor,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done
                        ? AppColors.success
                        : AppColors.body.withValues(alpha: 0.25),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22, top: 6),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.ink : AppColors.body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
