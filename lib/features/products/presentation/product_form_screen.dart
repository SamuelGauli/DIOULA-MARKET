import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/product.dart';
import 'product_controller.dart';

/// Unités proposées pour un produit.
const _units = ['unité', 'kg', 'sac', 'litre', 'régime', 'tas', 'carton'];

/// Formulaire de création / édition d'un produit.
/// Reçoit via `extra` un enregistrement (shopId, produitExistant?).
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({
    super.key,
    required this.shopId,
    this.existing,
  });

  final String shopId;
  final Product? existing;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _promo;
  late final TextEditingController _stock;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late String _unit;
  late String _saleMode;
  bool _loading = false;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _price = TextEditingController(text: p == null ? '' : p.price.toStringAsFixed(0));
    _promo = TextEditingController(
        text: p?.promoPrice == null ? '' : p!.promoPrice!.toStringAsFixed(0));
    _stock = TextEditingController(text: p == null ? '' : p.stock.toStringAsFixed(0));
    _description = TextEditingController(text: p?.description ?? '');
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
    _unit = p?.unit ?? 'unité';
    _saleMode = p?.saleMode ?? 'detail';
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _price.dispose();
    _promo.dispose();
    _stock.dispose();
    _description.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final product = Product(
      id: widget.existing?.id ?? '',
      shopId: widget.shopId,
      name: _name.text.trim(),
      category: _category.text.trim(),
      unit: _unit,
      price: double.tryParse(_price.text.replaceAll(',', '.')) ?? 0,
      stock: double.tryParse(_stock.text.replaceAll(',', '.')) ?? 0,
      description: _description.text.trim(),
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      promoPrice: _promo.text.trim().isEmpty
          ? null
          : double.tryParse(_promo.text.replaceAll(',', '.')),
      saleMode: _saleMode,
    );

    final ok = await ref
        .read(productControllerProvider.notifier)
        .save(product, isNew: _isNew);
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isNew ? 'Produit ajouté' : 'Produit mis à jour')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'enregistrement')),
      );
    }
  }

  String? _numberValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requis';
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null || n < 0) return 'Nombre invalide';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(_isNew ? 'Ajouter un produit' : 'Modifier le produit')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Nom du produit *',
                      prefixIcon: Icon(Icons.label_outline)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(
                      labelText: 'Catégorie (ex: Légumes)',
                      prefixIcon: Icon(Icons.category_outlined)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Prix (FCFA) *',
                            prefixIcon: Icon(Icons.payments_outlined)),
                        validator: _numberValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _unit,
                        decoration: const InputDecoration(labelText: 'Unité'),
                        items: _units
                            .map((u) =>
                                DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (u) => setState(() => _unit = u ?? _unit),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _saleMode,
                  decoration: const InputDecoration(
                      labelText: 'Type de vente',
                      helperText: 'Aide l\'acheteur à filtrer gros / détail',
                      prefixIcon: Icon(Icons.sell_outlined)),
                  items: kSaleModes
                      .map((m) => DropdownMenuItem(
                          value: m, child: Text(saleModeLabel(m))))
                      .toList(),
                  onChanged: (m) => setState(() => _saleMode = m ?? _saleMode),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _promo,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Prix promo (optionnel, anti-gaspillage)',
                      helperText: 'Laisse vide si pas de promotion',
                      prefixIcon: Icon(Icons.local_offer_outlined)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stock,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Stock disponible *',
                      prefixIcon: Icon(Icons.inventory_2_outlined)),
                  validator: _numberValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrl,
                  decoration: const InputDecoration(
                      labelText: 'URL d\'image (optionnel)',
                      prefixIcon: Icon(Icons.image_outlined)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.notes_outlined)),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isNew ? 'Ajouter' : 'Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
