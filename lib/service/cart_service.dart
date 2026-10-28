import 'package:get/get.dart';

import '../model/cart_item_model.dart';
import '../model/deal_model.dart';
import '../util/log_service.dart';
import 'flash_sale_service.dart';

/// App-wide cart. Lives for the whole session.
///
/// NOTE: the starter cart is purely local — it does not reserve stock on the
/// backend. See the "Reservations" feature task in PROBLEM.md.
class CartService extends GetxService {
  final FlashSaleService flashSaleService;

  CartService({required this.flashSaleService});

  final items = <CartItemModel>[].obs;
  final itemCount = 0.obs;
  final expiredDealNotices = <String>[].obs;
  Worker? _flashSaleWorker;

  @override
  void onInit() {
    super.onInit();
    // Remove expired items from the app-wide cart as soon as the shared clock
    // crosses their deadline, even when the user is on another screen.
    _flashSaleWorker = ever(flashSaleService.now, (_) => _removeExpiredDeals());
    _removeExpiredDeals();
  }

  bool add(DealModel deal) {
    if (flashSaleService.isExpired(deal)) {
      Get.snackbar(
        'Flash sale ended',
        'This deal is no longer available.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final existing = items.firstWhereOrNull((i) => i.deal.id == deal.id);
    if (existing != null) {
      if (existing.quantity >= deal.quantityLeft) {
        LogService.log('cart: cannot add more of deal ${deal.id}');
        return false;
      }
      existing.quantity++;
      items.refresh();
    } else {
      items.add(CartItemModel(deal: deal));
    }
    _recount();
    return true;
  }

  void decrement(int dealId) {
    final existing = items.firstWhereOrNull((i) => i.deal.id == dealId);
    if (existing == null) return;
    existing.quantity--;
    if (existing.quantity <= 0) {
      items.removeWhere((i) => i.deal.id == dealId);
    } else {
      items.refresh();
    }
    _recount();
  }

  void remove(int dealId) {
    items.removeWhere((i) => i.deal.id == dealId);
    _recount();
  }

  void clear() {
    items.clear();
    _recount();
  }

  void _removeExpiredDeals() {
    final expiredItems =
        items.where((item) => flashSaleService.isExpired(item.deal)).toList();
    if (expiredItems.isEmpty) return;

    final expiredIds = expiredItems.map((item) => item.deal.id).toSet();
    items.removeWhere((item) => expiredIds.contains(item.deal.id));
    _recount();

    final message = expiredItems.length == 1
        ? '${expiredItems.single.deal.name} was removed from your bag.'
        : 'Expired flash-sale deals were removed from your bag.';
    expiredDealNotices.add(message);

    // Keep an in-bag banner as a persistent fallback if this snackbar is missed.
    if (Get.currentRoute != '/cart') {
      Get.snackbar(
        'Flash sale ended',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void dismissExpiredDealNotice(int index) {
    if (index >= 0 && index < expiredDealNotices.length) {
      expiredDealNotices.removeAt(index);
    }
  }

  num get total => items.fold(0, (sum, i) => sum + i.lineTotal);

  void _recount() {
    itemCount.value = items.fold(0, (sum, i) => sum + i.quantity);
  }

  @override
  void onClose() {
    _flashSaleWorker?.dispose();
    super.onClose();
  }
}
