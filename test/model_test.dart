import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';

PickupWindowModel _window(String startUtc, String endUtc) =>
    PickupWindowModel.fromJson({'start': startUtc, 'end': endUtc});

void main() {
  test('DealModel parses API json', () {
    final deal = DealModel.fromJson({
      'id': 7,
      'name': 'Surprise Bakery Bag',
      'description': 'Assorted pastries',
      'imageUrl': 'https://example.com/img.jpg',
      'originalPrice': 150,
      'price': 49,
      'currencyCode': 'THB',
      'quantityLeft': 3,
      'storeId': 2,
      'storeName': 'Sunrise Bakehouse',
      'storeAddress': '1 Sukhumvit Soi 1, Bangkok',
      'lat': 13.75,
      'lng': 100.5,
      'rating': null,
      'tags': ['bestseller'],
      'pickupWindow': {
        'start': '2026-01-01T10:30:00.000Z',
        'end': '2026-01-01T14:00:00.000Z',
      },
      'flashSaleEndsAt': null,
    });

    expect(deal.id, 7);
    expect(deal.rating, isNull);
    expect(deal.discountPercent, 67);
    expect(deal.isFlashSale, isFalse);
    expect(deal.pickupWindow.start.isUtc, isTrue);
  });

  test('label shows market time (UTC+7) for UTC instants', () {
    // 06:00-09:30 Bangkok. Used to render "23:00 – 02:30" (RES-106).
    final w = _window('2026-10-26T23:00:00.000Z', '2026-10-27T02:30:00.000Z');
    expect(w.label, '06:00 – 09:30');
  });

  test('morning store counts as today at midday market time', () {
    // Starts on the previous UTC day, but is 27 Oct in the market.
    final w = _window('2026-10-26T23:00:00.000Z', '2026-10-27T02:30:00.000Z');
    expect(w.isTodayAt(DateTime.utc(2026, 10, 27, 5)), isTrue); // 12:00 Bangkok
  });

  test('window on a different market day is not today', () {
    final w = _window('2026-10-26T23:00:00.000Z', '2026-10-27T02:30:00.000Z');
    expect(w.isTodayAt(DateTime.utc(2026, 10, 28, 5)), isFalse); // 28 Oct
  });

  test('overnight window overlaps the day it ends on', () {
    // 22:00 on 27 Oct to 01:00 on 28 Oct, Bangkok.
    final w = _window('2026-10-27T15:00:00.000Z', '2026-10-27T18:00:00.000Z');
    expect(w.isTodayAt(DateTime.utc(2026, 10, 27, 17, 30)), isTrue); // 00:30
  });
}