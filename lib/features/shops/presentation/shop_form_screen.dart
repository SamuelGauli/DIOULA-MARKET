import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../data/shop_repository.dart';
import '../domain/shop.dart';
import 'shop_controller.dart';

/// Formulaire de création / édition d'une boutique.
/// [existing] est passé via `context.push(..., extra: shop)` pour l'édition.
class ShopFormScreen extends ConsumerStatefulWidget {
  const ShopFormScreen({super.key, this.existing});
  final Shop? existing;

  @override
  ConsumerState<ShopFormScreen> createState() => _ShopFormScreenState();
}

class _ShopFormScreenState extends ConsumerState<ShopFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _commune;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _description;
  String? _logoUrl;
  String? _bannerUrl;
  String? _picking; // 'logo' | 'banner' pendant l'upload
  bool _loading = false;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _category = TextEditingController(text: s?.category ?? '');
    _commune = TextEditingController(text: s?.commune ?? '');
    _address = TextEditingController(text: s?.address ?? '');
    _phone = TextEditingController(text: s?.phone ?? '');
    _description = TextEditingController(text: s?.description ?? '');
    _logoUrl = s?.logoUrl;
    _bannerUrl = s?.bannerUrl;
  }

  /// Choisit + téléverse une image de boutique. [kind] = 'logo' ou 'banner'.
  Future<void> _pickImage(String kind) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (x == null) return;
      setState(() => _picking = kind);
      final bytes = await x.readAsBytes();
      final url = await ref.read(shopRepositoryProvider).uploadShopImage(
            kind: kind,
            bytes: bytes,
            contentType: x.mimeType ?? 'image/jpeg',
          );
      setState(() {
        if (kind == 'logo') {
          _logoUrl = url;
        } else {
          _bannerUrl = url;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur d\'envoi : $e')));
      }
    } finally {
      if (mounted) setState(() => _picking = null);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _commune.dispose();
    _address.dispose();
    _phone.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    setState(() => _loading = true);
    // On part de la boutique existante (pour garder id/owner/géoloc) ou on
    // en crée une nouvelle.
    final shop = (widget.existing ??
            Shop(id: '', ownerId: uid, name: _name.text.trim()))
        .copyWith(
      name: _name.text.trim(),
      category: _category.text.trim(),
      commune: _commune.text.trim(),
      address: _address.text.trim(),
      phone: _phone.text.trim(),
      description: _description.text.trim(),
      logoUrl: _logoUrl,
      bannerUrl: _bannerUrl,
    );

    final ok =
        await ref.read(shopControllerProvider.notifier).save(shop, isNew: _isNew);
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isNew ? 'Boutique créée' : 'Boutique mise à jour')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'enregistrement')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isNew ? 'Créer ma boutique' : 'Modifier la boutique')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bannière (couverture) + logo superposé.
                _BannerLogoPicker(
                  bannerUrl: _bannerUrl,
                  logoUrl: _logoUrl,
                  picking: _picking,
                  onPickBanner: () => _pickImage('banner'),
                  onPickLogo: () => _pickImage('logo'),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Nom de la boutique *',
                      prefixIcon: Icon(Icons.storefront)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(
                      labelText: 'Catégorie (ex: Vivriers, Épicerie)',
                      prefixIcon: Icon(Icons.category_outlined)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commune,
                  decoration: const InputDecoration(
                      labelText: 'Commune (ex: Cocody)',
                      prefixIcon: Icon(Icons.location_city_outlined)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(
                      labelText: 'Adresse',
                      prefixIcon: Icon(Icons.home_outlined)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      prefixIcon: Icon(Icons.phone_outlined)),
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
                      : Text(_isNew ? 'Créer' : 'Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sélecteur d'images de la boutique : **bannière** (couverture) + **logo**
/// superposé, chacun cliquable pour choisir/téléverser une photo.
class _BannerLogoPicker extends StatelessWidget {
  const _BannerLogoPicker({
    required this.bannerUrl,
    required this.logoUrl,
    required this.picking,
    required this.onPickBanner,
    required this.onPickLogo,
  });

  final String? bannerUrl;
  final String? logoUrl;
  final String? picking; // 'logo' | 'banner' | null
  final VoidCallback onPickBanner;
  final VoidCallback onPickLogo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bannière.
          GestureDetector(
            onTap: onPickBanner,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.clay.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bannerUrl != null && bannerUrl!.isNotEmpty)
                    AppImage(url: bannerUrl!, fit: BoxFit.cover)
                  else
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: AppColors.clay),
                          SizedBox(height: 4),
                          Text('Ajouter une bannière',
                              style: TextStyle(
                                  color: AppColors.clay, fontSize: 12)),
                        ],
                      ),
                    ),
                  if (picking == 'banner')
                    Container(
                      color: Colors.black26,
                      child: const Center(
                          child: CircularProgressIndicator(color: Colors.white)),
                    ),
                ],
              ),
            ),
          ),
          // Logo (cercle) superposé en bas à gauche.
          Positioned(
            left: 16,
            bottom: 0,
            child: GestureDetector(
              onTap: onPickLogo,
              child: Container(
                height: 78,
                width: 78,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 3),
                          image: (logoUrl != null && logoUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: AppNetworkProvider.provider(logoUrl!),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: picking == 'logo'
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : (logoUrl == null || logoUrl!.isEmpty)
                        ? const Icon(Icons.storefront, color: AppColors.clay)
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
