import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../service/api_exception.dart';
import '../../service/analytics_service.dart';
import '../../service/cart_service.dart';
import '../../util/log_service.dart';

class DealDetailsController extends GetxController {
  final DealRepo dealRepo;
  final CartService cartService;
  final AnalyticsService analytics;

  DealDetailsController({
    required this.dealRepo,
    required this.cartService,
    required this.analytics,
  });

  final _deal = Rxn<DealModel>();
  DealModel? get deal => _deal.value;

  final isLoading = true.obs;
  final loadError = RxnString();

  // One worker per open deal details screen; it must not outlive this controller.
  Worker? _cartWorker;

  final _quantityLeft = RxnInt();
  int? get quantityLeft => _quantityLeft.value;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    if (arguments is DealModel) {
      _setDeal(arguments);
      isLoading.value = false;
      return;
    }

    // Deep links provide the deal ID in the URL, not a DealModel argument.
    final id = int.tryParse(Get.parameters['id'] ?? '');
    if (id == null || id <= 0) {
      loadError.value = 'This deal link is invalid.';
      isLoading.value = false;
      return;
    }
    _loadDeal(id);
  }

  Future<void> _loadDeal(int id) async {
    // The screen reads deal fields, so publish loading/error state until fetch completes.
    try {
      _setDeal(await dealRepo.fetchById(id));
    } on ApiException catch (e) {
      LogService.error('failed to load deal $id', e);
      loadError.value = e.statusCode == 404
          ? 'This deal could not be found.'
          : 'Unable to load this deal.';
    } on FormatException catch (e) {
      LogService.error('invalid deal response for $id', e);
      loadError.value = 'The deal information could not be read.';
    } finally {
      isLoading.value = false;
    }
  }

  void _setDeal(DealModel value) {
    _deal.value = value;
    _quantityLeft.value = value.quantityLeft;
    analytics.logEvent('deal_details_view', {
      'deal_id': value.id,
      'source': Get.parameters['source'] ?? 'unknown',
    });
    // Whenever the cart changes, re-check this deal's remaining stock so the
    // details screen never shows stale availability.
    _cartWorker ??= ever(
      cartService.itemCount,
      (_) => _recheckAvailability(),
    );
  }

  Future<void> _recheckAvailability() async {
    final currentDeal = deal;
    if (currentDeal == null) return;
    LogService.log('re-checking availability for deal ${currentDeal.id}');
    final fresh = await dealRepo.fetchById(currentDeal.id);
    _quantityLeft.value = fresh.quantityLeft;
  }

  @override
  void onClose() {
    // Stop observing cart changes after the details route is removed.
    _cartWorker?.dispose();
    super.onClose();
  }

  void addToCart() {
    final currentDeal = deal;
    if (currentDeal == null) return;
    cartService.add(currentDeal);
    Get.snackbar(
      'Added to bag',
      '${currentDeal.name} — pick up ${currentDeal.pickupWindow.label}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}
