import 'dart:async';

import 'package:get/get.dart';

import '../model/deal_model.dart';

class FlashSaleService extends GetxService {
  final DateTime Function() _clock;
  final Rx<DateTime> now;

  final Map<int, RxBool> _expiredDeals = {};
  final Map<int, DateTime> _activeDeadlines = {};
  Timer? _ticker;

  FlashSaleService({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        now = (clock ?? DateTime.now)().obs;

  @override
  void onInit() {
    super.onInit();
    // One ticker drives visible countdown text and expiry transitions app-wide.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  RxBool expirationState(DealModel deal) {
    return _expiredDeals.putIfAbsent(deal.id, () {
      final deadline = deal.flashSaleEndsAt;
      final expired = deadline == null || !deadline.isAfter(_clock());
      // Only active deadlines need an expiry notification; the shared clock
      // separately refreshes countdown text.
      if (!expired) _activeDeadlines[deal.id] = deadline;
      return expired.obs;
    });
  }

  bool isExpired(DealModel deal, [DateTime? at]) {
    final deadline = deal.flashSaleEndsAt;
    return deadline != null && !deadline.isAfter(at ?? _clock());
  }

  void _tick() {
    final current = _clock();
    now.value = current;

    final expiredIds = _activeDeadlines.entries
        .where((entry) => !entry.value.isAfter(current))
        .map((entry) => entry.key)
        .toList();

    for (final id in expiredIds) {
      _activeDeadlines.remove(id);
      _expiredDeals[id]?.value = true;
    }
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}
