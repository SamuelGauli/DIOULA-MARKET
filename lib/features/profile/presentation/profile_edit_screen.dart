import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../domain/profile.dart';
import '../data/profile_repository.dart';

/// Écran « Modifier mon profil » : photo de profil (upload) + nom, téléphone,
/// commune. Disponible pour tous les rôles (consommateur, livreur, vendeur…).
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _commune;
  String? _avatarUrl;
  bool _picking = false;
  bool _saving = false;
  bool _init = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _phone = TextEditingController();
    _commune = TextEditingController();
  }

  /// Pré-remplit les champs à partir du profil courant (une seule fois).
  void _seed(Profile p) {
    if (_init) return;
    _init = true;
    _name.text = p.fullName ?? '';
    _phone.text = p.phone ?? '';
    _commune.text = p.commune ?? '';
    _avatarUrl = p.avatarUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _commune.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final x = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (x == null) return;
      setState(() => _picking = true);
      final file = kIsWeb ? File.fromRawPath(await x.readAsBytes()) : File(x.path);
      final userId = ref.read(currentUserIdProvider)!;
      final url = await ref.read(profileRepositoryProvider).uploadAvatar(
            userId: userId,
            file: file,
          );
      setState(() => _avatarUrl = url);
    } catch (e) {
      _snack('Erreur d\'envoi de la photo : $e');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save(Profile current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final updated = Profile(
      id: current.id,
      role: current.role,
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      commune: _commune.text.trim(),
      avatarUrl: _avatarUrl,
      latitude: current.latitude,
      longitude: current.longitude,
    );
    try {
      await ref.read(profileRepositoryProvider).update(updated);
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      _snack('Profil mis à jour');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _snack('Erreur : $e');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    _seed(profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier mon profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Photo de profil + bouton d'édition.
                Center(
                  child: Stack(
                    children: [
                      UserAvatar(
                        name: _name.text.isEmpty ? profile.displayName : _name.text,
                        url: _avatarUrl,
                        radius: 52,
                        backgroundColor: AppColors.clay,
                        foregroundColor: Colors.white,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: AppColors.clay,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _picking ? null : _pickAvatar,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: _picking
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.photo_camera,
                                      size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text('Touche l\'appareil photo pour changer ta photo',
                      style: TextStyle(color: AppColors.body, fontSize: 12)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                  onChanged: (_) => setState(() {}), // rafraîchit l'initiale
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
                  controller: _commune,
                  decoration: const InputDecoration(
                      labelText: 'Commune (ex: Cocody)',
                      prefixIcon: Icon(Icons.location_city_outlined)),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : () => _save(profile),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
