import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shop_repository.dart';
import '../domain/shop.dart';

/// Actions sur la boutique (création / édition) avec gestion du chargement.
class ShopController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  ShopRepository get _repo => ref.read(shopRepositoryProvider);

  /// Enregistre la boutique. `isNew` = création, sinon mise à jour.
  /// Renvoie `true` si l'opération réussit.
  Future<bool> save(Shop shop, {required bool isNew}) async {
    state = const AsyncLoading();
    try {
      if (isNew) {
        await _repo.create(shop);
      } else {
        await _repo.update(shop);
      }
      // Rafraîchit la boutique affichée ailleurs dans l'app.
      ref.invalidate(myShopProvider);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

final shopControllerProvider =
    AsyncNotifierProvider<ShopController, void>(ShopController.new);
