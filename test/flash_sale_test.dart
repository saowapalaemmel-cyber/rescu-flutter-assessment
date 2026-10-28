import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/cart/cart_controller.dart';
import 'package:rescu/feature/cart/cart_screen.dart';
import 'package:rescu/feature/shared_widget/flash_sale_countdown.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/repository/order_repo.dart';
import 'package:rescu/service/cart_service.dart';
import 'package:rescu/service/fake_api_service.dart';
import 'package:rescu/service/flash_sale_service.dart';

DealModel _deal(DateTime endsAt) => DealModel(
      id: 1,
      name: 'Flash deal',
      description: '',
      imageUrl: '',
      originalPrice: 100,
      price: 50,
      currencyCode: 'THB',
      quantityLeft: 1,
      storeId: 1,
      storeName: 'Store',
      storeAddress: '',
      lat: 0,
      lng: 0,
      rating: null,
      tags: const [],
      pickupWindow: PickupWindowModel(
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 1, 1),
      ),
      flashSaleEndsAt: endsAt,
    );

void main() {
  tearDown(() {
    Get.reset();
  });

  test('formats countdowns as mm:ss or hh:mm:ss', () {
    expect(formatFlashSaleCountdown(const Duration(minutes: 5, seconds: 9)),
        '05:09');
    expect(formatFlashSaleCountdown(const Duration(hours: 1, seconds: 2)),
        '01:00:02');
    expect(formatFlashSaleCountdown(const Duration(milliseconds: 1)), '00:01');
    expect(formatFlashSaleCountdown(Duration.zero), 'Expired');
  });

  testWidgets('countdown updates and expires at its deadline', (tester) async {
    var now = DateTime.utc(2026, 10, 28);
    final service = FlashSaleService(clock: () => now);
    Get.put(service);
    final deal = _deal(now.add(const Duration(seconds: 2)));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlashSaleCountdown(deal: deal)),
      ),
    );
    expect(find.text('00:02'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Expired'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    Get.delete<FlashSaleService>(force: true);
  });

  testWidgets('cart keeps an expired-deal notice visible when empty',
      (tester) async {
    final flashSaleService = Get.put(FlashSaleService());
    final cartService =
        Get.put(CartService(flashSaleService: flashSaleService));
    cartService.expiredDealNotices.add('Flash deal was removed from your bag.');
    Get.put(
      CartController(
        cartService: cartService,
        orderRepo: OrderRepo(api: FakeApiService()),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: CartScreen()));

    expect(find.text('Your bag is empty'), findsOneWidget);
    expect(find.text('Flash deal was removed from your bag.'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss notice'));
    await tester.pump();

    expect(find.text('Flash deal was removed from your bag.'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    Get.delete<CartService>(force: true);
    Get.delete<FlashSaleService>(force: true);
  });
}
