import 'package:flutter/material.dart';

/// Canonical order fulfillment lifecycle stages, mirroring the
/// `Order.status` enum in `prestige-collection-backend` and the staged tracking
/// experience used by Daraz/Amazon-style order screens.
enum OrderStage {
  placed,
  paymentPending,
  paymentSuccessful,
  processing,
  packed,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  refunded,
}

class OrderStageInfo {
  final OrderStage stage;
  final String key;
  final String label;
  final IconData icon;

  const OrderStageInfo(this.stage, this.key, this.label, this.icon);
}

/// Maps backend `status` strings to display metadata (label/icon/color) and
/// exposes the ordered "happy path" timeline used for the tracking UI.
/// `cancelled`/`refunded` are terminal, off-path states rendered separately
/// rather than as a step in the timeline.
class OrderStatusHelper {
  OrderStatusHelper._();

  /// Ordered happy-path stages shown in the order tracking timeline.
  static const List<OrderStageInfo> timeline = [
    OrderStageInfo(OrderStage.placed, 'placed', 'Order Placed', Icons.receipt_long_outlined),
    OrderStageInfo(OrderStage.paymentPending, 'payment_pending', 'Payment Pending', Icons.schedule_outlined),
    OrderStageInfo(OrderStage.paymentSuccessful, 'payment_successful', 'Payment Successful', Icons.verified_outlined),
    OrderStageInfo(OrderStage.processing, 'processing', 'Processing', Icons.settings_outlined),
    OrderStageInfo(OrderStage.packed, 'packed', 'Packed', Icons.inventory_2_outlined),
    OrderStageInfo(OrderStage.shipped, 'shipped', 'Shipped', Icons.local_shipping_outlined),
    OrderStageInfo(OrderStage.outForDelivery, 'out_for_delivery', 'Out for Delivery', Icons.delivery_dining_outlined),
    OrderStageInfo(OrderStage.delivered, 'delivered', 'Delivered', Icons.task_alt_outlined),
  ];

  static const OrderStageInfo cancelledInfo =
      OrderStageInfo(OrderStage.cancelled, 'cancelled', 'Cancelled', Icons.cancel_outlined);
  static const OrderStageInfo refundedInfo =
      OrderStageInfo(OrderStage.refunded, 'refunded', 'Refunded', Icons.replay_circle_filled_outlined);

  /// Orders created before the lifecycle was expanded may still carry the
  /// older, simpler status values — map them onto the closest new stage.
  static const Map<String, String> _legacyAliases = {'pending': 'placed'};

  /// All admin-selectable status values, in lifecycle order.
  static List<String> get selectableKeys => [
        ...timeline.map((s) => s.key),
        cancelledInfo.key,
        refundedInfo.key,
      ];

  static const List<String> _onlinePaymentMethods = [
    'Credit Card',
    'Debit Card',
    'JazzCash',
    'easyPaisa',
  ];

  /// The happy-path steps relevant to [paymentMethod] — Cash on Delivery
  /// orders skip the payment confirmation stages since there's no online
  /// payment to wait on.
  static List<OrderStageInfo> timelineFor(String? paymentMethod) {
    if (_onlinePaymentMethods.contains(paymentMethod)) return timeline;
    return timeline
        .where((s) =>
            s.stage != OrderStage.paymentPending &&
            s.stage != OrderStage.paymentSuccessful)
        .toList();
  }

  static OrderStageInfo _infoOf(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    final resolved = _legacyAliases[value] ?? value;
    if (resolved == cancelledInfo.key) return cancelledInfo;
    if (resolved == refundedInfo.key) return refundedInfo;
    return timeline.firstWhere(
      (s) => s.key == resolved,
      orElse: () => timeline.first,
    );
  }

  static String label(String? raw) => _infoOf(raw).label;

  static IconData icon(String? raw) => _infoOf(raw).icon;

  static bool isCancelled(String? raw) => _infoOf(raw).stage == OrderStage.cancelled;

  static bool isRefunded(String? raw) => _infoOf(raw).stage == OrderStage.refunded;

  /// True for `cancelled`/`refunded` — terminal states that fall off the
  /// happy-path timeline.
  static bool isTerminalNegative(String? raw) => isCancelled(raw) || isRefunded(raw);

  /// Index into [timelineFor], or -1 for cancelled/refunded orders.
  static int timelineIndexFor(String? raw, String? paymentMethod) {
    final info = _infoOf(raw);
    if (info.stage == OrderStage.cancelled || info.stage == OrderStage.refunded) {
      return -1;
    }
    return timelineFor(paymentMethod).indexWhere((s) => s.stage == info.stage);
  }

  static Color color(ColorScheme cs, String? raw) {
    final info = _infoOf(raw);
    switch (info.stage) {
      case OrderStage.delivered:
        return cs.secondary;
      case OrderStage.cancelled:
        return cs.error;
      case OrderStage.refunded:
        return cs.tertiary;
      default:
        return cs.secondary;
    }
  }
}

/// Payment gateway status — separate from the fulfillment [OrderStage]
/// above. Tracks whether the money has actually been captured.
class PaymentStatusHelper {
  PaymentStatusHelper._();

  static String label(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'captured':
        return 'Paid';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return 'Pending';
    }
  }

  static IconData icon(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'captured':
        return Icons.check_circle_outline;
      case 'failed':
        return Icons.error_outline;
      case 'refunded':
        return Icons.replay_outlined;
      default:
        return Icons.schedule_outlined;
    }
  }

  static Color color(ColorScheme cs, String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'captured':
        return cs.secondary;
      case 'failed':
        return cs.error;
      default:
        return cs.tertiary;
    }
  }
}

/// Small pill used to surface a status (order stage or payment state)
/// consistently across My Orders, Order Details, and the admin orders
/// screen — matches the badge styling already established in those pages.
class StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class OrderStatusBadge extends StatelessWidget {
  final String? status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return StatusBadge(
      icon: OrderStatusHelper.icon(status),
      label: OrderStatusHelper.label(status),
      color: OrderStatusHelper.color(cs, status),
    );
  }
}

class PaymentStatusBadge extends StatelessWidget {
  final String? status;

  const PaymentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return StatusBadge(
      icon: PaymentStatusHelper.icon(status),
      label: PaymentStatusHelper.label(status),
      color: PaymentStatusHelper.color(cs, status),
    );
  }
}
