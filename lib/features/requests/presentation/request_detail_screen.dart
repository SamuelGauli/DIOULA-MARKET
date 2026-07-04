import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../shops/data/shop_repository.dart';
import '../data/requests_repository.dart';
import '../domain/market_request.dart';
import '../domain/offer.dart';
import 'widgets/request_bits.dart';

/// Détail d'une demande : infos + offres **en temps réel**.
/// - Le consommateur propriétaire voit/accepte les offres.
/// - Un vendeur (commerçant/producteur) peut soumettre une offre.
class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  Future<void> _accept(
      BuildContext context, WidgetRef ref, String offerId) async {
    try {
      await ref.read(requestsRepositoryProvider).acceptOffer(offerId);
      ref.invalidate(requestByIdProvider(requestId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Offre acceptée ✅ Commande créée, vendeur notifié.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(requestByIdProvider(requestId));
    final uid = ref.watch(supabaseProvider).auth.currentUser?.id;
    final role =
        ref.watch(currentProfileProvider).value?.role ?? UserRole.consommateur;

    return Scaffold(
      appBar: AppBar(title: const Text('Demande')),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (request) {
          if (request == null) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'Demande introuvable',
              message: 'Elle a peut-être été clôturée ou supprimée.',
            );
          }

          final isOwner = uid != null && uid == request.consumerId;
          final isSeller =
              role == UserRole.commercant || role == UserRole.producteur;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RequestHeader(request: request),
              const SizedBox(height: 20),
              if (isOwner)
                _OwnerOffers(
                  request: request,
                  onAccept: (offerId) => _accept(context, ref, offerId),
                )
              else if (isSeller && request.isOpen)
                _SellerOfferArea(request: request)
              else
                _ReadOnlyOffersCount(requestId: request.id),
            ],
          );
        },
      ),
    );
  }
}

// ----------------------- EN-TÊTE DEMANDE -----------------------
class _RequestHeader extends StatelessWidget {
  const _RequestHeader({required this.request});
  final MarketRequest request;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(request.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              RequestStatusChip(request: request),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(Icons.shopping_basket_outlined, requestSubtitle(request)),
          const SizedBox(height: 6),
          _InfoRow(Icons.schedule, expiresLabel(request.expiresAt)),
          if (request.description != null &&
              request.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(request.description!,
                style: const TextStyle(color: AppColors.body, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.body),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: AppColors.body, fontSize: 13)),
        ),
      ],
    );
  }
}

// ----------------------- OFFRES (vue propriétaire) -----------------------
class _OwnerOffers extends ConsumerWidget {
  const _OwnerOffers({required this.request, required this.onAccept});
  final MarketRequest request;
  final void Function(String offerId) onAccept;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersForRequestProvider(request.id));
    final shops = ref.watch(allShopsProvider).value ?? [];
    String shopName(String? id) {
      if (id == null) return 'Vendeur';
      final m = shops.where((s) => s.id == id);
      return m.isEmpty ? 'Vendeur' : m.first.name;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Offres reçues',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        offersAsync.when(
          loading: () =>
              const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator())),
          error: (e, _) => Text('Erreur : $e'),
          data: (offers) {
            if (offers.isEmpty) {
              return const EmptyState(
                icon: Icons.hourglass_empty,
                title: 'En attente d\'offres',
                message:
                    'Les vendeurs proches vont répondre. Ça se met à jour tout seul ⚡',
              );
            }
            return Column(
              children: [
                for (final o in offers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OfferCard(
                      offer: o,
                      shopName: shopName(o.shopId),
                      canAccept: request.isOpen && o.isPending,
                      onAccept: () => onAccept(o.id),
                      onNegotiate: request.isOpen
                          ? () => _openCounter(context, ref, o)
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.shopName,
    required this.canAccept,
    required this.onAccept,
    this.onNegotiate,
  });

  final Offer offer;
  final String shopName;
  final bool canAccept;
  final VoidCallback onAccept;

  /// Négociation (côté consommateur uniquement) : ouvre la contre-proposition.
  final VoidCallback? onNegotiate;

  @override
  Widget build(BuildContext context) {
    final qty = offer.quantity == null
        ? ''
        : ' · ${formatQty(offer.quantity!)} ${offer.unit ?? ''}';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, size: 18, color: AppColors.clay),
              const SizedBox(width: 6),
              Expanded(
                child: Text(shopName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              _OfferStatusChip(offer: offer),
            ],
          ),
          const SizedBox(height: 8),
          Text('${formatFcfa(offer.price)}$qty',
              style: const TextStyle(
                  color: AppColors.clay,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          if (offer.deliveryDelay != null &&
              offer.deliveryDelay!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _InfoRow(Icons.local_shipping_outlined, offer.deliveryDelay!),
          ],
          if (offer.message != null && offer.message!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(offer.message!,
                style: const TextStyle(color: AppColors.body)),
          ],
          if (canAccept) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Accepter',
                    icon: Icons.check,
                    gradient: true,
                    onPressed: onAccept,
                  ),
                ),
                if (onNegotiate != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onNegotiate,
                      icon: const Icon(Icons.handshake_outlined, size: 18),
                      label: const Text('Négocier'),
                    ),
                  ),
                ],
              ],
            ),
          ] else if (offer.isCountered && onNegotiate != null) ...[
            const SizedBox(height: 10),
            Text(
              'Contre-offre envoyée : ${formatFcfa(offer.counterPrice ?? 0)} '
              '— en attente du vendeur.',
              style: const TextStyle(
                  color: AppColors.ocre, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfferStatusChip extends StatelessWidget {
  const _OfferStatusChip({required this.offer});
  final Offer offer;
  @override
  Widget build(BuildContext context) {
    final color = switch (offer.status) {
      'acceptee' => AppColors.success,
      'refusee' => AppColors.danger,
      'contre_proposee' => AppColors.ocre,
      _ => AppColors.info,
    };
    final label = offer.isCountered ? 'Contre-offre' : offer.statusEnum.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }
}

/// Contre-proposition du client sur une offre (négociation).
Future<void> _openCounter(
    BuildContext context, WidgetRef ref, Offer offer) async {
  final price = TextEditingController(text: offer.price.toStringAsFixed(0));
  final msg = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Négocier le prix'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prix proposé par le vendeur : ${formatFcfa(offer.price)}',
              style: const TextStyle(color: AppColors.body)),
          const SizedBox(height: 12),
          TextField(
            controller: price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Ton prix (FCFA)',
                prefixIcon: Icon(Icons.payments_outlined)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: msg,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'Message (optionnel)',
                prefixIcon: Icon(Icons.notes_outlined)),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Envoyer')),
      ],
    ),
  );
  final pText = price.text;
  final mText = msg.text.trim();
  price.dispose();
  msg.dispose();
  if (ok != true) return;

  final p = double.tryParse(pText.replaceAll(',', '.'));
  if (p == null || p <= 0) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Prix invalide.')));
    }
    return;
  }
  try {
    await ref
        .read(requestsRepositoryProvider)
        .counterOffer(offer.id, p, mText.isEmpty ? null : mText);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contre-offre envoyée 💬')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }
}

/// Réponse du vendeur à une contre-offre (accepter le prix / refuser).
Future<void> _respondCounter(
    BuildContext context, WidgetRef ref, String offerId,
    {required bool accept}) async {
  try {
    final repo = ref.read(requestsRepositoryProvider);
    if (accept) {
      await repo.acceptCounter(offerId);
    } else {
      await repo.declineCounter(offerId);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(accept
            ? 'Prix accepté — le client peut confirmer.'
            : 'Prix maintenu.'),
      ));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }
}

// ----------------------- ZONE VENDEUR -----------------------
class _SellerOfferArea extends ConsumerWidget {
  const _SellerOfferArea({required this.request});
  final MarketRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(supabaseProvider).auth.currentUser?.id;
    final offersAsync = ref.watch(offersForRequestProvider(request.id));

    return offersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erreur : $e'),
      data: (offers) {
        final mine = offers.where((o) => o.merchantId == uid).toList();
        if (mine.isNotEmpty) {
          final o = mine.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Votre offre',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _OfferCard(
                offer: o,
                shopName: 'Votre boutique',
                canAccept: false,
                onAccept: () {},
              ),
              const SizedBox(height: 8),
              if (o.isCountered) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.ocre.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Le client propose ${formatFcfa(o.counterPrice ?? 0)} '
                    '(au lieu de ${formatFcfa(o.price)}).',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            _respondCounter(context, ref, o.id, accept: true),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Accepter le prix'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            _respondCounter(context, ref, o.id, accept: false),
                        child: const Text('Refuser'),
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  o.isAccepted
                      ? 'Votre offre a été acceptée 🎉'
                      : o.status == 'refusee'
                          ? 'Cette offre n\'a pas été retenue.'
                          : 'En attente de la décision du consommateur…',
                  style: const TextStyle(color: AppColors.body),
                ),
            ],
          );
        }
        return Column(
          children: [
            const EmptyState(
              icon: Icons.handshake_outlined,
              title: 'Répondez à cette demande',
              message:
                  'Proposez votre prix et votre délai. Le consommateur sera notifié.',
            ),
            PrimaryButton(
              label: 'Faire une offre',
              icon: Icons.local_offer,
              gradient: true,
              onPressed: () => _openOfferSheet(context, ref, request),
            ),
          ],
        );
      },
    );
  }
}

Future<void> _openOfferSheet(
    BuildContext context, WidgetRef ref, MarketRequest request) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OfferForm(request: request),
  );
}

class _OfferForm extends ConsumerStatefulWidget {
  const _OfferForm({required this.request});
  final MarketRequest request;

  @override
  ConsumerState<_OfferForm> createState() => _OfferFormState();
}

class _OfferFormState extends ConsumerState<_OfferForm> {
  final _formKey = GlobalKey<FormState>();
  final _price = TextEditingController();
  final _quantity = TextEditingController();
  final _delay = TextEditingController();
  final _message = TextEditingController();
  late String _unit = widget.request.unit ?? 'kg';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.request.quantity != null) {
      _quantity.text = formatQty(widget.request.quantity!);
    }
  }

  @override
  void dispose() {
    _price.dispose();
    _quantity.dispose();
    _delay.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final shop = ref.read(myShopProvider).value;
    final price = double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0;
    final qty = double.tryParse(_quantity.text.trim().replaceAll(',', '.'));
    try {
      await ref.read(requestsRepositoryProvider).submitOffer(
            requestId: widget.request.id,
            shopId: shop?.id,
            price: price,
            quantity: qty,
            unit: _unit,
            deliveryDelay:
                _delay.text.trim().isEmpty ? null : _delay.text.trim(),
            message:
                _message.text.trim().isEmpty ? null : _message.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offre envoyée ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text('Faire une offre',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _price,
                      label: 'Prix (FCFA)',
                      prefixIcon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Prix requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _quantity,
                      label: 'Quantité',
                      prefixIcon: Icons.numbers,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _unit,
                decoration: const InputDecoration(labelText: 'Unité'),
                items: kUnits
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setState(() => _unit = v ?? _unit),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _delay,
                label: 'Délai de livraison (ex: sous 2h, demain)',
                prefixIcon: Icons.schedule,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _message,
                label: 'Message (optionnel)',
                prefixIcon: Icons.notes,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Envoyer l\'offre',
                icon: Icons.send,
                gradient: true,
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------- LECTURE SEULE -----------------------
class _ReadOnlyOffersCount extends ConsumerWidget {
  const _ReadOnlyOffersCount({required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersForRequestProvider(requestId));
    final count = offersAsync.value?.length ?? 0;
    return EmptyState(
      icon: Icons.visibility_outlined,
      title: 'Demande en cours',
      message: count == 0
          ? 'Aucune offre pour le moment.'
          : '$count offre(s) reçue(s). Seul un vendeur peut répondre.',
    );
  }
}
