import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app_config.dart';

/// Live countdown until the pickup window opens.
class PickupCountdown extends StatefulWidget {
  final DateTime pickupStart;

  const PickupCountdown({super.key, required this.pickupStart});

  @override
  State<PickupCountdown> createState() => _PickupCountdownState();
}

class _PickupCountdownState extends State<PickupCountdown> {
  // Keep the periodic timer so it can be cancelled with this State.
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    // The countdown is tied to this widget's lifetime, not the app lifetime.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Prevent setState() after the State has been disposed when leaving the page.
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.pickupStart.difference(DateTime.now());
    final String text;
    if (remaining.isNegative) {
      text = 'Pickup window is open';
    } else {
      final h = remaining.inHours;
      final m = remaining.inMinutes % 60;
      final s = remaining.inSeconds % 60;
      text = h > 0
          ? 'Opens in ${h}h ${m}m'
          : 'Opens in ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined,
            size: 15, color: AppConfig.primaryGreen),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppConfig.primaryGreen)),
      ],
    );
  }
}
