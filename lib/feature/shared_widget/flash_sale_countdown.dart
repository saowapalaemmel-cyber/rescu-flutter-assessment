import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../service/flash_sale_service.dart';

class FlashSaleCountdown extends StatelessWidget {
  final DealModel deal;
  final TextStyle? style;

  const FlashSaleCountdown({
    super.key,
    required this.deal,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final flashSaleService = Get.find<FlashSaleService>();
    final expired = flashSaleService.expirationState(deal);
    final deadline = deal.flashSaleEndsAt;

    // Keep per-second rebuilds inside this text widget, not its parent card.
    return Obx(() {
      final now = flashSaleService.now.value;
      if (expired.value || deadline == null || !deadline.isAfter(now)) {
        return Text('Expired', style: style);
      }

      return Text(
        formatFlashSaleCountdown(deadline.difference(now)),
        style: style,
      );
    });
  }
}

String formatFlashSaleCountdown(Duration remaining) {
  final totalSeconds = (remaining.inMilliseconds / 1000).ceil();
  if (totalSeconds <= 0) return 'Expired';

  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  final totalMinutes = totalSeconds ~/ 60;
  return '${totalMinutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
