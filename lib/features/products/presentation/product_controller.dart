import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/product_repository.dart';
import '../domain/product.dart';

/// Actions CRUD sur les produits, avec gestion du chargement/erreur.
class ProductController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  ProductRepository get _repo => ref.read(productRepositoryProvider);

  /// Crée ou met à jour un produit. Renvoie `true` si succès.
  Future<bool> save(Product product, {required bool isNew}) async {
    state = const AsyncLoading();
    try {
      if (isNew) {
        await _repo.create(product);
      } else {
        await _repo.update(product);
      }
      ref.invalidate(productsByShopProvider(product.shopId));
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// Supprime un produit.
  Future<bool> delete(Product product) async {
    state = const AsyncLoading();
    try {
      await _repo.delete(product.id);
      ref.invalidate(productsByShopProvider(product.shopId));
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

final productControllerProvider =
    AsyncNotifierProvider<ProductController, void>(ProductController.new);
