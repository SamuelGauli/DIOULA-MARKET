import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../profile/data/profile_repository.dart';
import '../data/requests_repository.dart';

/// Formulaire de publication d'une **demande instantanée** (consommateur).
class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _product = TextEditingController();
  final _quantity = TextEditingController();
  final _description = TextEditingController();

  String _unit = 'kg';
  double _radius = 10;
  int _deadlineHours = 24;
  bool _loading = false;

  static const _deadlines = <(String, int)>[
    ('6 h', 6),
    ('24 h', 24),
    ('2 j', 48),
    ('3 j', 72),
  ];

  @override
  void dispose() {
    _product.dispose();
    _quantity.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final product = _product.text.trim();
    final qty = double.tryParse(_quantity.text.trim().replaceAll(',', '.'));
    final title =
        qty == null ? product : '${formatQty(qty)} $_unit · $product';
    final profile = ref.read(currentProfileProvider).value;

    try {
      await ref.read(requestsRepositoryProvider).createRequest(
            title: title,
            productName: product,
            quantity: qty,
            unit: _unit,
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            radiusKm: _radius,
            latitude: profile?.latitude,
            longitude: profile?.longitude,
            expiresAt: DateTime.now().add(Duration(hours: _deadlineHours)),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande publiée ⚡ Les vendeurs sont notifiés.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle demande')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppTextField(
              controller: _product,
              label: 'Produit recherché',
              prefixIcon: Icons.shopping_basket_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Produit requis' : null,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _quantity,
                    label: 'Quantité',
                    prefixIcon: Icons.numbers,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(labelText: 'Unité'),
                    items: kUnits
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v ?? _unit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Label('Rayon de recherche : ${formatQty(_radius)} km'),
            Slider(
              value: _radius,
              min: 1,
              max: 50,
              divisions: 49,
              activeColor: AppColors.clay,
              label: '${formatQty(_radius)} km',
              onChanged: (v) => setState(() => _radius = v),
            ),
            const SizedBox(height: 8),
            const _Label('Échéance'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                for (final d in _deadlines)
                  ChoiceChip(
                    label: Text(d.$1),
                    selected: _deadlineHours == d.$2,
                    onSelected: (_) => setState(() => _deadlineHours = d.$2),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _description,
              label: 'Détails (optionnel)',
              prefixIcon: Icons.notes,
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Publier la demande',
              icon: Icons.bolt,
              gradient: true,
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13));
  }
}
